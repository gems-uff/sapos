# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "roo"
require "set"
require "zip"

# Companion of Admissions::AdmissionExportHelper: rebuilds an admission process
# ("edital") from the .zip it produces (edital.xlsx + files/ + files/long_values/).
#
# The reading layer (module functions below) unpacks the archive, parses the
# sheets with Roo and converts cells back to column values. Importer (at the end
# of the file) recreates the records inside one transaction:
#   - shared configuration (form templates, ranking machines, ranking configs,
#     committees, phases) is reused when the record with the original id still
#     exists and is identical to the exported one, children included; otherwise a
#     frozen copy is created and nothing that already exists is changed;
#   - everything owned by the process (applications, filled forms, evaluations,
#     results, pendencies...) is always created, with new ids;
#   - users are matched by email; records of a missing user are dropped, as
#     User's dependent: :destroy would have done.
# The original ids are translated to the new ones through an id map.
module Admissions::AdmissionImportHelper
  class ImportError < StandardError; end

  # Outcome of an import: counts per table, plus what was dropped or adjusted.
  Report = Struct.new(:dry_run, :process_id, :created, :reused, :warnings, :errors, keyword_init: true) do
    def success?
      errors.empty?
    end

    def tables
      (created.keys + reused.keys).uniq
    end
  end

  # Every table sheet the export writes, in its (dependency) order.
  SHEETS = %w[
    form_templates form_fields form_conditions admission_processes admission_phases
    admission_process_phases admission_committees admission_committee_members
    admission_phase_committees ranking_configs ranking_columns ranking_groups
    ranking_processes ranking_machines admission_process_rankings filled_forms
    filled_form_fields filled_form_field_scholarities admission_applications
    letter_requests admission_phase_evaluations admission_phase_results
    admission_ranking_results admission_pendencies
  ].freeze

  FORMAT_VERSION = Admissions::AdmissionExportHelper::FORMAT_VERSION
  LONG_VALUE_DIR = Admissions::AdmissionExportHelper::LONG_VALUE_DIR
  LONG_VALUE_SENTINEL = Admissions::AdmissionExportHelper::LONG_VALUE_SENTINEL
  EXPECTED_ROOT_MODEL = "Admissions::AdmissionProcess"
  META_SHEET = "meta"
  XLSX_ENTRY = "edital.xlsx"
  FILES_PREFIX = "files/"
  LONG_VALUES_PREFIX = "files/#{LONG_VALUE_DIR}/"
  # Keeps a corrupted or malicious entry (zip bomb) from being inflated in full.
  MAX_ENTRY_BYTES = 500.megabytes

  module_function

  # Imports the archive in +io+ and returns a Report. With +dry_run+ the whole
  # import runs and is rolled back, so the report previews what would happen.
  # An ImportError aborts the import (nothing is written) and lands in
  # report.errors; any other exception propagates.
  def import_zip(io, dry_run: false)
    report = Report.new(
      dry_run: dry_run, process_id: nil, created: Hash.new(0), reused: Hash.new(0),
      warnings: [], errors: []
    )
    archive = read_archive(io)
    meta, sheets = with_workbook(archive[:xlsx]) do |workbook|
      [validate_meta!(read_meta(workbook)), SHEETS.index_with { |name| read_sheet(workbook, name) }]
    end
    # requires_new: inside a caller's transaction a joined block would swallow the
    # Rollback without undoing anything; a savepoint makes dry_run and errors undo.
    ActiveRecord::Base.transaction(requires_new: true) do
      Importer.new(meta, sheets, archive[:files], archive[:long_values], report).run
      raise ActiveRecord::Rollback if dry_run
    end
    report.warnings.uniq!
    report
  rescue ImportError => e
    report.created.clear
    report.reused.clear
    report.process_id = nil
    report.errors << e.message
    report
  end

  # --- Archive reading -------------------------------------------------------

  # Unpacks +io+ (anything Zip::File.open_buffer accepts: a String or an IO)
  # into { xlsx: <bytes>, files: { entry_name => bytes }, long_values: { name => bytes } }.
  # Only the entries the export is known to write are read; nothing is driven by
  # paths an attacker could control beyond this fixed layout.
  def read_archive(io)
    xlsx_bytes = nil
    files = {}
    long_values = {}
    Zip::File.open_buffer(io) do |zip|
      xlsx_entry = zip.glob(XLSX_ENTRY).first
      raise ImportError, "#{XLSX_ENTRY} não encontrado no arquivo" if xlsx_entry.nil?

      xlsx_bytes = read_entry(xlsx_entry)
      zip.each do |entry|
        next unless entry.file?

        name = utf8(entry.name, "o nome da entrada #{entry.name.inspect}")
        next if name == XLSX_ENTRY

        if name.start_with?(LONG_VALUES_PREFIX)
          long_values[name.delete_prefix(LONG_VALUES_PREFIX)] = utf8(read_entry(entry), "o valor longo #{name}")
        elsif name.start_with?(FILES_PREFIX)
          files[name.delete_prefix(FILES_PREFIX)] = read_entry(entry)
        end
        # Anything else in the archive (stray entries) is ignored.
      end
    end
    { xlsx: xlsx_bytes, files: files, long_values: long_values }
  rescue Zip::Error => e
    raise ImportError, "arquivo não é um .zip válido: #{e.message}"
  end

  def read_entry(entry)
    if entry.size > MAX_ENTRY_BYTES
      raise ImportError, "entrada '#{entry.name}' excede o tamanho máximo permitido (#{MAX_ENTRY_BYTES} bytes)"
    end
    entry.get_input_stream.read
  end

  # The zip hands entries back as binary, but the export wrote names and long
  # values as UTF-8. Left binary, the first accent breaks the save: SQLite's
  # adapter transcodes a binary string to UTF-8 and raises on any byte above 127.
  def utf8(bytes, what)
    string = bytes.dup.force_encoding(Encoding::UTF_8)
    raise ImportError, "#{what} não está em UTF-8" unless string.valid_encoding?

    string
  end

  # --- Workbook reading --------------------------------------------------

  # Writes +xlsx_bytes+ to a temp file and opens it with Roo. Yields the
  # workbook and always discards the temp file afterwards.
  def with_workbook(xlsx_bytes)
    tempfile = Tempfile.new(["edital_import", ".xlsx"])
    tempfile.binmode
    tempfile.write(xlsx_bytes)
    tempfile.close
    yield Roo::Excelx.new(tempfile.path)
  rescue Roo::FileNotFound, Zip::Error => e
    raise ImportError, "edital.xlsx não pôde ser lido: #{e.message}"
  ensure
    tempfile&.unlink
  end

  # Reads the "meta" sheet (a 2-column key/value table) into a plain Hash.
  def read_meta(workbook)
    raise ImportError, "aba '#{META_SHEET}' não encontrada" unless workbook.sheets.include?(META_SHEET)

    workbook.default_sheet = META_SHEET
    meta = {}
    (2..workbook.last_row.to_i).each do |i|
      key, value = workbook.row(i)
      next if key.blank?

      meta[key] = value
    end
    meta
  end

  # Raises unless the archive is a format this importer understands and is
  # rooted at an admission process, as the export always writes.
  def validate_meta!(meta)
    format_version = meta["format_version"].to_s
    if format_version != FORMAT_VERSION.to_s
      raise ImportError, "versão do arquivo (#{format_version.presence || "ausente"}) " \
        "incompatível com a versão suportada (#{FORMAT_VERSION})"
    end
    if meta["sapos_root_model"] != EXPECTED_ROOT_MODEL
      raise ImportError, "arquivo não é uma exportação de edital (sapos_root_model=#{meta["sapos_root_model"].inspect})"
    end
    meta
  end

  # Reads a table sheet (header row + one row per record) into an array of
  # { header_string => raw_cell_string_or_nil } hashes, in file order. Returns
  # [] for a sheet the archive doesn't have (older/partial export) or that has
  # only the header row.
  def read_sheet(workbook, name)
    sheet = Admissions::AdmissionExportHelper.sheet_name(name)
    return [] unless workbook.sheets.include?(sheet)

    workbook.default_sheet = sheet
    header = workbook.row(1)
    return [] if header.nil?

    (2..workbook.last_row.to_i).map do |i|
      row = workbook.row(i)
      header.each_with_index.to_h { |column, index| [column, row[index]] }
    end
  end

  # --- Cell value conversion -------------------------------------------------

  # Resolves a cell's raw value: nil/blank becomes nil, and the "@@FILE:" sentinel
  # is swapped for the overflowed content stored in files/long_values/.
  def resolve_cell(raw, long_values)
    return nil if raw.nil?

    string = raw.to_s
    return nil if string.empty?
    return string unless string.start_with?(LONG_VALUE_SENTINEL)

    path = string.delete_prefix(LONG_VALUE_SENTINEL)
    name = path.delete_prefix("#{LONG_VALUE_DIR}/")
    long_values.fetch(name) do
      raise ImportError, "valor longo referenciado e ausente do arquivo: #{path}"
    end
  end

  # Converts a resolved string value to what +model+'s +column+ expects before
  # assignment: back through JSON for a serialized column (e.g. FilledFormField#list,
  # exported as a JSON array/hash by stringify), left as a string otherwise — the
  # usual date/number/boolean columns are cast by ActiveRecord on assignment.
  def typed_value(model, column, string)
    return nil if string.nil?
    return string unless serialized_column?(model, column)

    begin
      JSON.parse(string)
    rescue JSON::ParserError
      string
    end
  end

  def serialized_column?(model, column)
    model.attribute_types[column.to_s].is_a?(ActiveRecord::Type::Serialized)
  end

  # Builds the attributes hash to assign on a new/loaded record of +model+ from
  # one +row+ (as returned by read_sheet), translated through +long_values+.
  # Columns the sheet has but the model no longer does are skipped, with a
  # warning appended to +warnings+ (a column the model has but the sheet lacks
  # is simply left at its default). +skip_columns+ (e.g. "id", "file") lets the
  # caller take those over explicitly instead.
  def row_attributes(model, row, long_values, warnings: [], sheet: nil, skip_columns: [])
    known_columns = model.column_names
    row.each_with_object({}) do |(column, raw), attrs|
      next if skip_columns.include?(column)

      unless known_columns.include?(column)
        warnings << "#{sheet}: coluna '#{column}' não existe mais em #{model.name} e foi ignorada"
        next
      end

      resolved = resolve_cell(raw, long_values)
      attrs[column] = typed_value(model, column, resolved)
    end
  end

  # Rebuilds the records of one archive. It keeps state across the steps (id map,
  # dropped rows, lookups), hence a class; import_zip runs it inside its transaction.
  class Importer
    MODELS = {
      "form_templates" => "Admissions::FormTemplate",
      "form_fields" => "Admissions::FormField",
      "form_conditions" => "Admissions::FormCondition",
      "admission_processes" => "Admissions::AdmissionProcess",
      "admission_phases" => "Admissions::AdmissionPhase",
      "admission_process_phases" => "Admissions::AdmissionProcessPhase",
      "admission_committees" => "Admissions::AdmissionCommittee",
      "admission_committee_members" => "Admissions::AdmissionCommitteeMember",
      "admission_phase_committees" => "Admissions::AdmissionPhaseCommittee",
      "ranking_configs" => "Admissions::RankingConfig",
      "ranking_columns" => "Admissions::RankingColumn",
      "ranking_groups" => "Admissions::RankingGroup",
      "ranking_processes" => "Admissions::RankingProcess",
      "ranking_machines" => "Admissions::RankingMachine",
      "admission_process_rankings" => "Admissions::AdmissionProcessRanking",
      "filled_forms" => "Admissions::FilledForm",
      "filled_form_fields" => "Admissions::FilledFormField",
      "filled_form_field_scholarities" => "Admissions::FilledFormFieldScholarity",
      "admission_applications" => "Admissions::AdmissionApplication",
      "letter_requests" => "Admissions::LetterRequest",
      "admission_phase_evaluations" => "Admissions::AdmissionPhaseEvaluation",
      "admission_phase_results" => "Admissions::AdmissionPhaseResult",
      "admission_ranking_results" => "Admissions::AdmissionRankingResult",
      "admission_pendencies" => "Admissions::AdmissionPendency",
    }.freeze

    # Left out when comparing an exported record with the one in the database.
    IGNORED_COLUMNS = %w[id created_at updated_at].freeze
    # Tables the archive doesn't carry. Their ids are resolved through the natural
    # key the export writes as an extra "<association>__<attribute>" column.
    EXTERNAL_TABLES = %w[users levels enrollment_statuses enrollments students].freeze
    # Rows that point to a user. A user missing here drops the row (decision: same
    # effect as User's dependent: :destroy).
    USER_TABLES = %w[admission_committee_members admission_phase_evaluations admission_pendencies].freeze

    # Shared configuration is reused or copied one unit at a time: the root, the
    # children pointing to it (table, foreign key to the root), the condition trees
    # it points to, and the form template it owns (a ranking config's own template).
    # A copied unit never points into another unit's records, and a copy cascades:
    # once a committee is copied, the phase's translated admission_committee_id no
    # longer matches, so the phase is copied too.
    TEMPLATE_UNIT = {
      table: "form_templates", children: [%w[form_fields form_template_id]],
      conditions: [], templates: []
    }.freeze
    UNITS = [
      TEMPLATE_UNIT,
      { table: "ranking_machines", children: [],
        conditions: %w[form_condition_id], templates: [] },
      { table: "ranking_configs",
        children: [
          %w[ranking_columns ranking_config_id], %w[ranking_groups ranking_config_id],
          %w[ranking_processes ranking_config_id]
        ],
        conditions: %w[form_condition_id], templates: %w[form_template_id] },
      { table: "admission_committees",
        children: [%w[admission_committee_members admission_committee_id]],
        conditions: %w[form_condition_id], templates: [] },
      { table: "admission_phases",
        children: [%w[admission_phase_committees admission_phase_id]],
        conditions: %w[approval_condition_id keep_in_phase_condition_id], templates: [] },
    ].freeze

    # Owned by the process: always created, in this (dependency) order.
    OWNED_TABLES = %w[
      admission_processes admission_process_phases admission_process_rankings
      filled_forms filled_form_fields filled_form_field_scholarities
      admission_applications letter_requests admission_phase_evaluations
      admission_phase_results admission_ranking_results admission_pendencies
    ].freeze

    def initialize(meta, sheets, files, long_values, report)
      @meta = meta
      @rows = sheets
      @files = files
      @long_values = long_values
      @report = report
      @by_id = sheets.transform_values { |rows| rows.index_by { |row| to_id(row["id"]) } }
      @id_map = Hash.new { |hash, table| hash[table] = {} }
      @excluded = Hash.new { |hash, table| hash[table] = Set.new }
      @lookups = Hash.new { |hash, key| hash[key] = {} }
      @foreign_keys = {}
      @mismatch = nil
    end

    def run
      root = root_process_row
      refuse_duplicate!(root)
      exclude_rows_of_missing_users
      import_files
      import_shared_configuration
      import_owned_records(root)
      @report.process_id = @id_map["admission_processes"][to_id(root["id"])]
    end

    private
      # --- Preconditions ----------------------------------------------------

      def root_process_row
        root_id = to_id(@meta["root_admission_process_id"])
        @by_id["admission_processes"][root_id] ||
          raise(ImportError, "o edital raiz (id #{root_id}) não está na aba admission_processes")
      end

      def refuse_duplicate!(row)
        name = value(row, "name")
        exists = Admissions::AdmissionProcess.where(
          id: to_id(row["id"]), name: name, year: value(row, "year"), semester: value(row, "semester")
        ).exists?
        return unless exists

        raise ImportError, "o edital \"#{name}\" (#{value(row, "year")}.#{value(row, "semester")}) " \
          "ainda existe nesta base; exclua-o antes de importá-lo"
      end

      # Drops the rows of users missing here, and the filled form of a dropped
      # evaluation with its fields, so no orphan form is left behind. One warning
      # per user, with the count per table: a real process drops hundreds of rows.
      def exclude_rows_of_missing_users
        dropped = Hash.new { |hash, email| hash[email] = Hash.new(0) }
        USER_TABLES.each do |table|
          @rows[table].each do |row|
            next if to_id(row["user_id"]).nil? || user_id(row)

            @excluded[table] << to_id(row["id"])
            filled_form_id = to_id(row["filled_form_id"])
            @excluded["filled_forms"] << filled_form_id if filled_form_id
            dropped[row["user__email"].presence || "sem e-mail"][table] += 1
          end
        end
        dropped.each do |email, counts|
          summary = counts.map { |table, count| "#{count} em #{table}" }.join(", ")
          add_warning("usuário #{email} não encontrado nesta base; registros descartados: #{summary}")
        end
        exclude_children("filled_form_fields", "filled_form_id", "filled_forms")
        exclude_children("filled_form_field_scholarities", "filled_form_field_id", "filled_form_fields")
      end

      def exclude_children(table, column, parent_table)
        @rows[table].each do |row|
          @excluded[table] << to_id(row["id"]) if @excluded[parent_table].include?(to_id(row[column]))
        end
      end

      # --- Files ------------------------------------------------------------

      # Storage is content addressed ("<md5>.<ext>"), so a file already stored here
      # is reused as is and only the missing ones are written.
      def import_files
        storage = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
        available = @files.to_h do |name, bytes|
          medium_hash, original_filename = name.split("__", 2)
          [medium_hash, [original_filename, bytes]]
        end
        referenced_file_hashes.each do |medium_hash|
          stored_id = storage.where(medium_hash: medium_hash).pick(:id)
          if stored_id
            @report.reused["carrier_wave_files"] += 1
          else
            original_filename, bytes = available[medium_hash]
            if bytes.nil?
              add_warning("arquivo #{medium_hash} referenciado por um formulário não veio no .zip " \
                "nem existe nesta base")
              next
            end
            stored_id = store_file(storage, medium_hash, original_filename, bytes)
          end
          CarrierwaveOrphanFile.where(carrierwave_file_id: stored_id).delete_all
        end
      end

      def referenced_file_hashes
        @rows["filled_form_fields"]
          .reject { |row| excluded?("filled_form_fields", row) }
          .filter_map { |row| value(row, "file") }
          .uniq
      end

      def store_file(storage, medium_hash, original_filename, bytes)
        if Digest::MD5.hexdigest(bytes) != medium_hash.split(".", 2).first
          raise ImportError, "o arquivo #{medium_hash} está corrompido (o conteúdo não confere com o hash)"
        end

        record = storage.create!(
          medium_hash: medium_hash,
          original_filename: original_filename,
          content_type: Rack::Mime.mime_type(File.extname(original_filename.to_s)),
          size: bytes.bytesize,
          binary: bytes
        )
        @report.created["carrier_wave_files"] += 1
        record.id
      end

      # --- Shared configuration ---------------------------------------------

      def import_shared_configuration
        # A ranking config owns its form template: it goes with the config's unit.
        ranking_templates = @rows["ranking_configs"].filter_map { |row| to_id(row["form_template_id"]) }.to_set
        UNITS.each do |unit|
          table = unit[:table]
          @rows[table].each do |row|
            old_id = to_id(row["id"])
            next if table == "form_templates" && ranking_templates.include?(old_id)
            next if @id_map[table].key?(old_id)

            @mismatch = nil
            if unit_matches?(unit, old_id)
              reuse_unit(unit, old_id)
            else
              add_warning("#{table} id #{old_id}: criada uma cópia, pois #{@mismatch}")
              copy_unit(unit, old_id)
            end
          end
        end
      end

      # Inside a unit the ids are compared as they are (the candidate for reuse is
      # the record with the same id); references out of it go through the id map.
      def internal_tables(unit)
        tables = [unit[:table]] + unit[:children].map(&:first)
        tables << "form_conditions" if unit[:conditions].any?
        tables += internal_tables(TEMPLATE_UNIT) if unit[:templates].any?
        tables
      end

      def unit_matches?(unit, old_id)
        table = unit[:table]
        row = @by_id[table][old_id]
        return false if row.nil?

        internal = internal_tables(unit)
        return false unless same_record?(table, row, model_for(table).find_by(id: old_id), internal)

        unit[:children].all? { |child_table, column| children_match?(child_table, column, old_id, internal) } &&
          unit[:conditions].all? { |column| condition_tree_matches?(to_id(row[column])) } &&
          unit[:templates].all? do |column|
            template_id = to_id(row[column])
            template_id.nil? || unit_matches?(TEMPLATE_UNIT, template_id)
          end
      end

      # The children in the database are exactly the exported ones, each identical.
      def children_match?(table, column, parent_id, internal)
        exported = child_rows(table, column, parent_id)
        existing = model_for(table).where(column => parent_id).index_by(&:id)
        exported_ids = exported.map { |row| to_id(row["id"]) }.sort
        if exported_ids != existing.keys.sort
          return mismatch("#{table} difere (ids no arquivo #{exported_ids}, na base #{existing.keys.sort})")
        end

        exported.all? { |row| same_record?(table, row, existing[to_id(row["id"])], internal) }
      end

      def condition_tree_matches?(old_id)
        return true if old_id.nil?

        row = @by_id["form_conditions"][old_id]
        return mismatch("form_conditions id #{old_id} não está no arquivo") if row.nil?
        return false unless same_record?(
          "form_conditions", row, Admissions::FormCondition.find_by(id: old_id), ["form_conditions"]
        )

        children_match?("form_conditions", "parent_id", old_id, ["form_conditions"]) &&
          child_rows("form_conditions", "parent_id", old_id).all? do |child|
            condition_tree_matches?(to_id(child["id"]))
          end
      end

      def same_record?(table, row, existing, internal)
        return mismatch("#{table} id #{row["id"]} não existe nesta base") if existing.nil?

        exported = comparable(table, attributes_for(table, row, internal: internal, warn_unresolved: false))
        current = comparable(table, existing.attributes)
        column = exported.keys.find { |key| exported[key] != current[key] }
        return true if column.nil?

        mismatch("#{table} id #{row["id"]} difere em #{column} " \
          "(no arquivo #{exported[column].inspect.truncate(60)}, na base #{current[column].inspect.truncate(60)})")
      end

      # Keeps the first reason a unit didn't match, for the report. Returns false.
      def mismatch(reason)
        @mismatch ||= reason
        false
      end

      # Column values cast to the column type, blanks as nil and times to the
      # second: the export writes nil and "" alike and drops sub-second precision.
      def comparable(table, values)
        model = model_for(table)
        (model.column_names - IGNORED_COLUMNS).to_h do |column|
          cast = model.type_for_attribute(column).cast(values[column])
          cast = nil if cast.respond_to?(:empty?) && cast.empty?
          cast = cast.to_i if cast.acts_like?(:time)
          [column, cast]
        end
      end

      def reuse_unit(unit, old_id)
        row = @by_id[unit[:table]][old_id]
        mark_reused(unit[:table], old_id)
        unit[:children].each do |child_table, column|
          child_rows(child_table, column, old_id).each { |child| mark_reused(child_table, to_id(child["id"])) }
        end
        unit[:conditions].each { |column| reuse_condition_tree(to_id(row[column])) }
        unit[:templates].each do |column|
          template_id = to_id(row[column])
          reuse_unit(TEMPLATE_UNIT, template_id) if template_id
        end
      end

      def reuse_condition_tree(old_id)
        return if old_id.nil? || @id_map["form_conditions"].key?(old_id)

        mark_reused("form_conditions", old_id)
        child_rows("form_conditions", "parent_id", old_id).each do |child|
          reuse_condition_tree(to_id(child["id"]))
        end
      end

      def mark_reused(table, id)
        @id_map[table][id] = id
        @report.reused[table] += 1
      end

      # Owned parts first (template, condition trees), so the root's references
      # to them translate to the copies.
      def copy_unit(unit, old_id)
        table = unit[:table]
        row = @by_id[table][old_id]
        if row.nil?
          add_warning("#{table} id #{old_id} é referenciado mas não está no arquivo")
          return
        end
        return if @id_map[table].key?(old_id)

        unit[:templates].each do |column|
          template_id = to_id(row[column])
          copy_unit(TEMPLATE_UNIT, template_id) if template_id
        end
        unit[:conditions].each { |column| copy_condition_tree(to_id(row[column])) }
        create_record(table, row)
        unit[:children].each do |child_table, column|
          child_rows(child_table, column, old_id).each { |child| create_record(child_table, child) }
        end
      end

      def copy_condition_tree(old_id)
        return if old_id.nil? || @id_map["form_conditions"].key?(old_id)

        row = @by_id["form_conditions"][old_id]
        if row.nil?
          add_warning("form_conditions id #{old_id} é referenciado mas não está no arquivo")
          return
        end
        create_record("form_conditions", row)
        child_rows("form_conditions", "parent_id", old_id).each do |child|
          copy_condition_tree(to_id(child["id"]))
        end
      end

      # The ERB/Ruby guard of FormField (cannot_create_new_erb_template) is skipped
      # by save(validate: false), and an archive must not become a way to bring new
      # server-side code in. A copied field may only carry code this database
      # already knows: in a current field, or in the history of the original one.
      def check_unsafe_code!(field, row)
        current = field.template_values
        return unless current[0]

        known = Admissions::FormField.where(field_type: field.field_type).any? do |other|
          other.template_values == current
        end
        known ||= PaperTrail::Version.where(
          item_type: Admissions::FormField.name, item_id: to_id(row["id"])
        ).any? { |version| version.reify&.template_values == current }
        return if known

        raise ImportError, "o campo \"#{field.name}\" traz código Ruby/ERB que não existe nesta base; " \
          "por segurança a importação não cria código novo"
      end

      # --- Records owned by the process ---------------------------------------

      def import_owned_records(root)
        OWNED_TABLES.each do |table|
          rows = table == "admission_processes" ? [root] : @rows[table]
          rows.each do |row|
            next if excluded?(table, row)

            case table
            when "admission_processes" then import_process(row)
            when "filled_form_fields" then import_filled_form_field(row)
            when "admission_applications"
              create_record(table, row, with_free_token(table, row, Admissions::AdmissionApplication, "token"))
            when "letter_requests"
              create_record(table, row, with_free_token(table, row, Admissions::LetterRequest, "access_token"))
            else
              create_record(table, row)
            end
          end
        end
      end

      # An open process keeps its simple_url only if no other open process with an
      # overlapping period uses it (the model's own rule).
      def import_process(row)
        create_record("admission_processes", row) do |process|
          next if process.simple_url.blank? || process.end_date.blank? || process.end_date < Date.today

          process.valid?
          next if process.errors[:simple_url].empty?

          add_warning("o simple_url \"#{process.simple_url}\" já é usado por outro edital aberto; " \
            "o edital foi importado sem ele")
          process.simple_url = nil
        end
      end

      # The file column is written raw after the save: assigned through the
      # uploader, the hash string would be taken for a file to store.
      def import_filled_form_field(row)
        attrs = attributes_for("filled_form_fields", row)
        medium_hash = attrs.delete("file")
        record = create_record("filled_form_fields", row, attrs)
        record.update_column(:file, medium_hash) if medium_hash.present?
      end

      # A token already taken here is cleared, so before_save generates a new one.
      def with_free_token(table, row, model, column)
        attrs = attributes_for(table, row)
        token = attrs[column]
        if token.present? && model.exists?(column => token)
          attrs[column] = nil
          add_warning("#{table} id #{row["id"]}: o token já é usado nesta base; um novo foi gerado")
        end
        attrs
      end

      # --- Record building ----------------------------------------------------

      # Saved without validations: the data was valid when exported, and the
      # current rules (required fields added later, option SQL, ERB guard) could
      # reject it. The attributes are assigned again after new because the
      # after_initialize hooks (FilledFormField defaults, RankingColumn
      # conversion) fill blank columns and would change the archived values.
      def create_record(table, row, attrs = attributes_for(table, row))
        record = model_for(table).new(attrs)
        record.assign_attributes(attrs)
        check_unsafe_code!(record, row) if record.is_a?(Admissions::FormField)
        yield record if block_given?
        record.save!(validate: false)
        @id_map[table][to_id(row["id"])] = record.id
        @report.created[table] += 1
        record
      end

      # Column values of +row+ for its model, with foreign keys translated. A key
      # into one of the +internal+ tables keeps the original id (comparison with
      # the record of the same id); an unresolved key becomes nil.
      def attributes_for(table, row, internal: [], warn_unresolved: true)
        plain = row.reject { |column, _| column.include?("__") }
        attrs = Admissions::AdmissionImportHelper.row_attributes(
          model_for(table), plain, @long_values,
          warnings: @report.warnings, sheet: table, skip_columns: ["id"]
        )
        foreign_keys(table).each do |column, target|
          old_id = to_id(attrs[column])
          next if old_id.nil?

          attrs[column] = translate_id(target, old_id, row, internal)
          next unless attrs[column].nil? && warn_unresolved

          add_warning("#{table} id #{row["id"]}: #{column}=#{old_id} (#{target}) não foi encontrado; " \
            "gravado vazio")
        end
        attrs
      end

      def translate_id(target, old_id, row, internal)
        return old_id if internal.include?(target)
        return external_id(target, row) if EXTERNAL_TABLES.include?(target)

        @id_map[target][old_id]
      end

      def foreign_keys(table)
        @foreign_keys[table] ||= model_for(table).reflect_on_all_associations(:belongs_to)
          .reject(&:polymorphic?)
          .to_h { |association| [association.foreign_key.to_s, association.klass.table_name] }
      end

      def external_id(table, row)
        case table
        when "users" then user_id(row)
        when "levels" then lookup(Level, :name, value(row, "level__name"))
        when "enrollment_statuses" then lookup(EnrollmentStatus, :name, value(row, "enrollment_status__name"))
        when "enrollments" then lookup(Enrollment, :enrollment_number, value(row, "enrollment__number"))
        when "students"
          lookup(Student, :cpf, value(row, "student__cpf")) ||
            Enrollment.where(id: external_id("enrollments", row)).pick(:student_id)
        end
      end

      def user_id(row)
        email = value(row, "user__email").to_s.strip.downcase
        return nil if email.empty?

        @lookups["users"].fetch(email) do
          @lookups["users"][email] = User.where("LOWER(email) = ?", email).pick(:id)
        end
      end

      def lookup(model, column, key)
        return nil if key.blank?

        cache = @lookups[[model.name, column]]
        cache.fetch(key) { cache[key] = model.where(column => key).pick(:id) }
      end

      # --- Small utilities ----------------------------------------------------

      def child_rows(table, column, parent_id)
        @rows[table].select { |row| to_id(row[column]) == parent_id && !excluded?(table, row) }
      end

      def excluded?(table, row)
        @excluded[table].include?(to_id(row["id"]))
      end

      def model_for(table)
        MODELS.fetch(table).constantize
      end

      def value(row, column)
        Admissions::AdmissionImportHelper.resolve_cell(row[column], @long_values)
      end

      def to_id(raw)
        raw.blank? ? nil : raw.to_s.to_i
      end

      def add_warning(message)
        @report.warnings << message
      end
  end
end

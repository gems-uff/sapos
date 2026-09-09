# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "axlsx"
require "zip"
require "set"

# Exports a whole admission process ("edital") to a .zip archive containing:
#   - edital.xlsx  : one worksheet per table of the admission graph (structure,
#                    forms, candidates and internal data). Original database ids are
#                    kept in the cells so the relationships can be rebuilt on import.
#   - files/       : every uploaded document referenced by filled_form_fields, named
#                    "<medium_hash>__<original_filename>" for mapping back on import.
#   - files/long_values/ : overflow for cell values above the xlsx 32k char limit,
#                    referenced from the cell by the "@@FILE:" sentinel.
#
# The companion import (see AdmissionImportHelper, próxima etapa) reads edital.xlsx,
# recreates the records translating the original ids through an id map and reattaches
# the files from files/.
module Admissions::AdmissionExportHelper
  FORMAT_VERSION = 1
  # Excel hard limit is 32767 chars per cell; stay safely below it.
  MAX_CELL_LENGTH = 32_000
  LONG_VALUE_DIR = "long_values"
  LONG_VALUE_SENTINEL = "@@FILE:"

  module_function

  # Returns the binary content of the .zip archive for the given admission process.
  def export_zip(process, exported_at: Time.current)
    data = collect(process)
    files = {}
    long_values = {}
    xlsx = build_xlsx(process, data, long_values, exported_at)
    collect_files(data[:filled_form_fields], files)
    build_zip(xlsx, files, long_values)
  end

  def export_filename(process)
    slug = (process.simple_url.presence || process.id).to_s.parameterize
    "edital_#{process.year}_#{process.semester}_#{slug}.zip"
  end

  # --- Graph collection ----------------------------------------------------

  # Walks the whole object graph rooted at +process+ and returns a hash of
  # { sheet_name_symbol => [records...] }, each list deduplicated by id.
  def collect(process)
    applications = process.admission_applications.order(:id).to_a

    process_phases = process.phases.order(:id).to_a
    admission_phases = uniq_by_id(process_phases.map(&:admission_phase))

    phase_committees = uniq_by_id(admission_phases.flat_map(&:admission_phase_committees))
    committees = uniq_by_id(phase_committees.map(&:admission_committee))
    committee_members = uniq_by_id(committees.flat_map(&:members))

    process_rankings = process.rankings.order(:id).to_a
    ranking_results = uniq_by_id(applications.flat_map(&:rankings))
    ranking_configs = uniq_by_id(
      process_rankings.map(&:ranking_config) + ranking_results.map(&:ranking_config)
    )
    ranking_columns = uniq_by_id(ranking_configs.flat_map(&:ranking_columns))
    ranking_groups = uniq_by_id(ranking_configs.flat_map(&:ranking_groups))
    ranking_processes = uniq_by_id(ranking_configs.flat_map(&:ranking_processes))
    ranking_machines = uniq_by_id(ranking_processes.map(&:ranking_machine))

    letter_requests = uniq_by_id(applications.flat_map(&:letter_requests))
    evaluations = uniq_by_id(applications.flat_map(&:evaluations))
    results = uniq_by_id(applications.flat_map(&:results))
    pendencies = uniq_by_id(applications.flat_map(&:pendencies))

    filled_forms = uniq_by_id([
      applications.map(&:filled_form),
      letter_requests.map(&:filled_form),
      evaluations.map(&:filled_form),
      results.map(&:filled_form),
      ranking_results.map(&:filled_form),
    ].flatten)
    filled_form_fields = uniq_by_id(filled_forms.flat_map(&:fields))
    scholarities = uniq_by_id(filled_form_fields.flat_map(&:scholarities))

    form_templates = uniq_by_id([
      process.form_template, process.letter_template,
      admission_phases.flat_map do |phase|
        [phase.member_form, phase.shared_form, phase.consolidation_form, phase.candidate_form]
      end,
      ranking_configs.map(&:form_template),
      filled_forms.map(&:form_template),
    ].flatten)
    form_fields = uniq_by_id(form_templates.flat_map(&:fields))

    root_conditions = [
      admission_phases.flat_map { |phase| [phase.approval_condition, phase.keep_in_phase_condition] },
      committees.map(&:form_condition),
      ranking_configs.map(&:form_condition),
      ranking_machines.map(&:form_condition),
    ].flatten
    form_conditions = collect_conditions(root_conditions)

    {
      form_templates: form_templates,
      form_fields: form_fields,
      form_conditions: form_conditions,
      admission_processes: [process],
      admission_phases: admission_phases,
      admission_process_phases: process_phases,
      admission_committees: committees,
      admission_committee_members: committee_members,
      admission_phase_committees: phase_committees,
      ranking_configs: ranking_configs,
      ranking_columns: ranking_columns,
      ranking_groups: ranking_groups,
      ranking_processes: ranking_processes,
      ranking_machines: ranking_machines,
      admission_process_rankings: process_rankings,
      filled_forms: filled_forms,
      filled_form_fields: filled_form_fields,
      filled_form_field_scholarities: scholarities,
      admission_applications: applications,
      letter_requests: letter_requests,
      admission_phase_evaluations: evaluations,
      admission_phase_results: results,
      admission_ranking_results: ranking_results,
      admission_pendencies: pendencies,
    }
  end

  # Walks the recursive form_condition tree (parent -> form_conditions children).
  def collect_conditions(roots)
    seen = {}
    stack = roots.compact
    until stack.empty?
      condition = stack.pop
      next if condition.nil? || seen.key?(condition.id)

      seen[condition.id] = condition
      stack.concat(condition.form_conditions.to_a)
    end
    seen.values
  end

  def uniq_by_id(records)
    records.compact.uniq(&:id)
  end

  # --- Spreadsheet building ------------------------------------------------

  def build_xlsx(process, data, long_values, exported_at)
    previous_escape = Axlsx.escape_formulas
    # Keep cell values byte-for-byte (no leading-quote injection on "=", "+", "-", "@")
    # so the spreadsheet round-trips losslessly. Cells are written as :string anyway,
    # so Excel never evaluates them as formulas.
    Axlsx.escape_formulas = false
    package = Axlsx::Package.new
    workbook = package.workbook
    add_meta_sheet(workbook, process, data, exported_at)
    table_definitions(data).each { |definition| add_table_sheet(workbook, definition, long_values) }
    package.to_stream.read
  ensure
    Axlsx.escape_formulas = previous_escape
  end

  # One descriptor per worksheet: which table becomes which sheet, with which records.
  # Ordered so that, on import, every sheet only references ids already created by a
  # previous sheet (dependency order). NOTE: these are spreadsheet definitions, not tests.
  def table_definitions(data)
    [
      table_definition("form_templates", Admissions::FormTemplate, data[:form_templates]),
      table_definition("form_fields", Admissions::FormField, data[:form_fields]),
      table_definition("form_conditions", Admissions::FormCondition, data[:form_conditions]),
      table_definition("admission_processes", Admissions::AdmissionProcess, data[:admission_processes],
        "level__name" => ->(r) { r.level&.name },
        "enrollment_status__name" => ->(r) { r.enrollment_status&.name }),
      table_definition("admission_phases", Admissions::AdmissionPhase, data[:admission_phases]),
      table_definition("admission_process_phases", Admissions::AdmissionProcessPhase, data[:admission_process_phases]),
      table_definition("admission_committees", Admissions::AdmissionCommittee, data[:admission_committees]),
      table_definition("admission_committee_members", Admissions::AdmissionCommitteeMember, data[:admission_committee_members],
        "user__email" => ->(r) { r.user&.email },
        "user__name" => ->(r) { r.user&.name }),
      table_definition("admission_phase_committees", Admissions::AdmissionPhaseCommittee, data[:admission_phase_committees]),
      table_definition("ranking_configs", Admissions::RankingConfig, data[:ranking_configs]),
      table_definition("ranking_columns", Admissions::RankingColumn, data[:ranking_columns]),
      table_definition("ranking_groups", Admissions::RankingGroup, data[:ranking_groups]),
      table_definition("ranking_processes", Admissions::RankingProcess, data[:ranking_processes]),
      table_definition("ranking_machines", Admissions::RankingMachine, data[:ranking_machines]),
      table_definition("admission_process_rankings", Admissions::AdmissionProcessRanking, data[:admission_process_rankings]),
      table_definition("filled_forms", Admissions::FilledForm, data[:filled_forms]),
      table_definition("filled_form_fields", Admissions::FilledFormField, data[:filled_form_fields]),
      table_definition("filled_form_field_scholarities", Admissions::FilledFormFieldScholarity, data[:filled_form_field_scholarities]),
      table_definition("admission_applications", Admissions::AdmissionApplication, data[:admission_applications],
        "student__name" => ->(r) { r.student&.name },
        "enrollment__number" => ->(r) { r.enrollment&.enrollment_number }),
      table_definition("letter_requests", Admissions::LetterRequest, data[:letter_requests]),
      table_definition("admission_phase_evaluations", Admissions::AdmissionPhaseEvaluation, data[:admission_phase_evaluations],
        "user__email" => ->(r) { r.user&.email },
        "user__name" => ->(r) { r.user&.name }),
      table_definition("admission_phase_results", Admissions::AdmissionPhaseResult, data[:admission_phase_results]),
      table_definition("admission_ranking_results", Admissions::AdmissionRankingResult, data[:admission_ranking_results]),
      table_definition("admission_pendencies", Admissions::AdmissionPendency, data[:admission_pendencies],
        "user__email" => ->(r) { r.user&.email },
        "user__name" => ->(r) { r.user&.name }),
    ]
  end

  # Builds a single worksheet descriptor consumed by add_table_sheet.
  def table_definition(name, model, records, extras = {})
    { name: name, model: model, records: records || [], extras: extras }
  end

  def add_meta_sheet(workbook, process, data, exported_at)
    workbook.add_worksheet(name: "meta") do |sheet|
      sheet.add_row(%w[key value], types: %i[string string])
      rows = {
        "format_version" => FORMAT_VERSION,
        "exported_at" => exported_at.iso8601,
        "sapos_root_model" => "Admissions::AdmissionProcess",
        "root_admission_process_id" => process.id,
        "admission_process_title" => process.title,
      }
      data.each { |key, records| rows["count__#{key}"] = records.size }
      rows.each { |key, value| sheet.add_row([key, value.to_s], types: %i[string string]) }
    end
  end

  def add_table_sheet(workbook, definition, long_values)
    columns = definition[:model].column_names
    extras = definition[:extras]
    header = columns + extras.keys
    string_types = Array.new(header.size, :string)
    workbook.add_worksheet(name: sheet_name(definition[:name])) do |sheet|
      sheet.add_row(header, types: string_types)
      definition[:records].each do |record|
        row = columns.map do |column|
          cell_value(serialize_cell(record, column), definition[:name], record, column, long_values)
        end
        extras.each do |key, getter|
          row << cell_value(stringify(getter.call(record)), definition[:name], record, key, long_values)
        end
        sheet.add_row(row, types: string_types)
      end
    end
  end

  # Worksheet names are limited to 31 chars and a few forbidden characters.
  def sheet_name(name)
    name.gsub(%r{[\[\]:*?/\\]}, "_")[0, 31]
  end

  # Reads the raw attribute (not the CarrierWave uploader for :file) and stringifies it.
  def serialize_cell(record, column)
    stringify(record[column])
  end

  def stringify(raw)
    case raw
    when nil then ""
    when Array, Hash then JSON.dump(raw)
    else
      return raw.iso8601 if raw.respond_to?(:iso8601)
      raw.to_s
    end
  end

  # Keeps values under the xlsx cell limit, spilling overflow to files/long_values/.
  def cell_value(string, sheet, record, column, long_values)
    return "" if string.nil? || string.empty?
    return string if string.length <= MAX_CELL_LENGTH

    name = "#{sheet}__#{record.id}__#{column}.txt"
    long_values[name] = string
    "#{LONG_VALUE_SENTINEL}#{LONG_VALUE_DIR}/#{name}"
  end

  # --- Files ---------------------------------------------------------------

  def collect_files(filled_form_fields, files)
    cw = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    seen = Set.new
    filled_form_fields.each do |field|
      medium_hash = field.read_attribute(:file)
      next if medium_hash.blank?
      next unless seen.add?(medium_hash) # same file referenced twice -> store once

      record = cw.where(medium_hash: medium_hash).first
      next if record.nil?

      files[file_entry_name(medium_hash, record.original_filename)] = record.read
    end
  end

  def file_entry_name(medium_hash, original_filename)
    safe = original_filename.to_s.gsub(%r{[\\/]}, "_")
    safe = "file" if safe.empty?
    "#{medium_hash}__#{safe}"
  end

  # --- Zip -----------------------------------------------------------------

  def build_zip(xlsx, files, long_values)
    Zip::OutputStream.write_buffer do |zos|
      zos.put_next_entry("edital.xlsx")
      zos.write(xlsx)
      files.each do |name, binary|
        zos.put_next_entry("files/#{name}")
        zos.write(binary)
      end
      long_values.each do |name, content|
        zos.put_next_entry("files/#{LONG_VALUE_DIR}/#{name}")
        zos.write(content)
      end
    end.string
  end
end

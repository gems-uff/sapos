# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionImportHelper, type: :helper do
  def storage
    CarrierWave::Storage::ActiveRecord::ActiveRecordFile
  end

  def models
    Admissions::AdmissionImportHelper::Importer::MODELS
  end

  # Tables owned by the process: what the panel's purge will delete.
  def owned_tables
    Admissions::AdmissionImportHelper::Importer::OWNED_TABLES
  end

  def model(table)
    models.fetch(table).constantize
  end

  def counts
    models.keys.index_with { |table| model(table).count }
  end

  def purge_process
    owned_tables.reverse_each { |table| model(table).delete_all }
    storage.delete_all
  end

  # Empties every admission table, as in another installation.
  def purge_everything
    models.each_key { |table| model(table).delete_all }
    storage.delete_all
    PaperTrail::Version.where("item_type LIKE ?", "Admissions::%").delete_all
  end

  def import(zip, dry_run: false)
    described_class.import_zip(zip, dry_run: dry_run)
  end

  # Rebuilds +zip+ passing every entry through the block, which returns the new
  # content, or nil to drop the entry.
  def rewrite_zip(zip)
    entries = {}
    Zip::File.open_buffer(StringIO.new(zip)) do |archive|
      archive.each { |entry| entries[entry.name] = entry.get_input_stream.read if entry.file? }
    end
    Zip::OutputStream.write_buffer do |out|
      entries.each do |name, bytes|
        bytes = yield(name, bytes)
        next if bytes.nil?

        out.put_next_entry(name)
        out.write(bytes)
      end
    end.string
  end

  let(:file_bytes) { "%PDF-1.4 conteúdo de teste".b }
  let(:medium_hash) { "#{Digest::MD5.hexdigest(file_bytes)}.pdf" }
  # Accented on purpose, like original_filename below: the zip hands both back
  # as binary, and SQLite refuses to save a binary string with an accent.
  let(:long_value) { "ação " * 8_000 }

  let!(:member) { FactoryBot.create(:user) }
  let!(:form_template) { FactoryBot.create(:form_template, name: "Inscrição") }
  let!(:text_field) { FactoryBot.create(:form_field, form_template: form_template, name: "Nome") }
  let!(:file_field) do
    FactoryBot.create(:form_field, form_template: form_template, name: "Documento",
      field_type: Admissions::FormField::FILE)
  end
  let!(:letter_template) do
    FactoryBot.create(:form_template, name: "Carta", template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER)
  end
  let!(:process) do
    FactoryBot.create(:admission_process, form_template: form_template, letter_template: letter_template)
  end
  let!(:approval_condition) do
    parent = FactoryBot.create(:form_condition, mode: Admissions::FormCondition::AND, field: nil)
    FactoryBot.create(:form_condition, mode: Admissions::FormCondition::NONE, parent: parent)
    parent
  end
  let!(:phase) do
    FactoryBot.create(:admission_phase, :with_member_form, :with_shared_form, approval_condition: approval_condition)
  end
  let!(:committee) { FactoryBot.create(:admission_committee) }
  let!(:committee_member) { FactoryBot.create(:admission_committee_member, admission_committee: committee, user: member) }
  let!(:phase_committee) do
    FactoryBot.create(:admission_phase_committee, admission_phase: phase, admission_committee: committee)
  end
  let!(:process_phase) { FactoryBot.create(:admission_process_phase, admission_process: process, admission_phase: phase) }
  let!(:ranking_config) { FactoryBot.create(:ranking_config) }
  let!(:process_ranking) do
    FactoryBot.create(:admission_process_ranking, admission_process: process, ranking_config: ranking_config)
  end
  let!(:application) do
    filled_form = FactoryBot.create(:filled_form, form_template: form_template, is_filled: true)
    text = FactoryBot.create(:filled_form_field, filled_form: filled_form, form_field: text_field, value: long_value)
    FactoryBot.create(:filled_form_field_scholarity, filled_form_field: text)
    # Neither value nor uploaded file through the uploader: the file column is set raw below.
    upload = FactoryBot.build(:filled_form_field, filled_form: filled_form, form_field: file_field, value: nil)
    upload.save!(validate: false)
    storage.create!(medium_hash: medium_hash, original_filename: "currículo.pdf", content_type: "application/pdf",
      size: file_bytes.bytesize, binary: file_bytes)
    upload.update_column(:file, medium_hash)
    FactoryBot.create(:admission_application, admission_process: process, filled_form: filled_form,
      email: "ana@example.com", admission_phase: phase)
  end
  let!(:other_application) do
    FactoryBot.create(:admission_application, admission_process: process, email: "bia@example.com",
      filled_form: FactoryBot.create(:filled_form, form_template: form_template))
  end
  let!(:letter) do
    FactoryBot.create(:letter_request, admission_application: application,
      filled_form: FactoryBot.create(:filled_form, form_template: letter_template))
  end
  let!(:evaluation) do
    FactoryBot.create(:admission_phase_evaluation, admission_phase: phase, user: member, admission_application: application,
      filled_form: FactoryBot.create(:filled_form, form_template: phase.member_form))
  end
  let!(:result) do
    FactoryBot.create(:admission_phase_result, admission_phase: phase, admission_application: application,
      filled_form: FactoryBot.create(:filled_form, form_template: phase.shared_form))
  end
  let!(:ranking_result) do
    FactoryBot.create(:admission_ranking_result, ranking_config: ranking_config, admission_application: application,
      filled_form: FactoryBot.create(:filled_form, form_template: ranking_config.form_template))
  end
  let!(:pendency) do
    FactoryBot.create(:admission_pendency, admission_phase: phase, admission_application: application, user: member)
  end

  let(:zip) { Admissions::AdmissionExportHelper.export_zip(process) }

  def imported_application
    Admissions::AdmissionApplication.find_by(email: "ana@example.com")
  end

  context "restoring into the same database" do
    it "reuses the unchanged configuration and brings the process data back" do
      zip
      original = { token: application.token, created_at: application.created_at.to_i }
      config_before = counts.except(*owned_tables)
      purge_process

      report = import(zip)

      expect(report.errors).to be_empty
      expect(report.created.keys & %w[form_templates admission_phases ranking_configs admission_committees])
        .to be_empty, report.warnings.join("\n")
      expect(counts.except(*owned_tables)).to eq(config_before)

      restored = imported_application
      expect(restored.token).to eq(original[:token])
      expect(restored.created_at.to_i).to eq(original[:created_at])
      expect(restored.admission_phase_id).to eq(phase.id)
      expect(restored.admission_process_id).to eq(report.process_id)
      expect(restored.filled_form.fields.find_by(form_field: text_field).value).to eq(long_value)
      expect(restored.filled_form.fields.find_by(form_field: text_field).scholarities.count).to eq(1)
      expect(restored.filled_form.fields.find_by(form_field: file_field).read_attribute(:file)).to eq(medium_hash)
      expect(storage.find_by(medium_hash: medium_hash).binary).to eq(file_bytes)
      expect(restored.letter_requests.count).to eq(1)
      expect(restored.evaluations.count).to eq(1)
      expect(restored.results.count).to eq(1)
      expect(restored.rankings.count).to eq(1)
      expect(Admissions::AdmissionApplication.count).to eq(2)
    end

    it "copies configuration edited since the export, cascading to whoever points to it" do
      zip
      purge_process
      phase.member_form.update!(name: "Avaliação renomeada")

      expect { import(zip) }
        .to change(Admissions::FormTemplate, :count).by(1)
        .and change(Admissions::AdmissionPhase, :count).by(1)

      expect(phase.member_form.reload.name).to eq("Avaliação renomeada")
      copied_phase = imported_application.admission_phase
      expect(copied_phase.id).not_to eq(phase.id)
      expect(copied_phase.member_form.name).to eq("Formulario")
      expect(copied_phase.approval_condition_id).not_to eq(approval_condition.id)
      expect(copied_phase.approval_condition.form_conditions.count).to eq(1)
      expect(copied_phase.admission_committees).to eq([committee])
    end
  end

  it "recreates everything with new ids in an empty database" do
    zip
    purge_everything

    report = import(zip)

    expect(report.errors).to be_empty
    expect(report.reused.except("carrier_wave_files")).to be_empty
    expect(Admissions::AdmissionProcess.count).to eq(1)
    expect(Admissions::AdmissionApplication.count).to eq(2)
    restored = imported_application
    expect(restored.admission_process.form_template.fields.pluck(:name)).to contain_exactly("Nome", "Documento")
    expect(restored.admission_phase.admission_committees.first.users).to eq([member])
    expect(restored.rankings.first.ranking_config.form_template).to be_present
    expect(restored.rankings.first.filled_form.form_template).to eq(restored.rankings.first.ranking_config.form_template)
    expect(restored.filled_form.fields.find_by(form_field: restored.admission_process.form_template.fields
      .find_by(name: "Nome")).value).to eq(long_value)
    stored = storage.find_by(medium_hash: medium_hash)
    expect(stored.binary).to eq(file_bytes)
    expect(stored.original_filename).to eq("currículo.pdf")
  end

  it "refuses to import a process that still exists" do
    zip
    before = counts

    report = import(zip)

    expect(report.errors.first).to include("ainda existe")
    expect(counts).to eq(before)
  end

  it "drops the records of a user missing in this database" do
    zip
    dropped = [
      Admissions::AdmissionCommitteeMember, Admissions::AdmissionPhaseEvaluation, Admissions::AdmissionPendency,
    ].map { |klass| "#{klass.where(user: member).count} em #{klass.table_name}" }
    purge_process
    # Lookup is by email: another email is a user this database doesn't have.
    archived_email = member.email
    member.update_column(:email, "outra.pessoa@example.com")

    report = import(zip)

    expect(report.errors).to be_empty
    expect(Admissions::AdmissionPhaseEvaluation.count).to eq(0)
    expect(Admissions::FilledForm.where(form_template: phase.member_form).count).to eq(0)
    # One warning per user, not one per dropped row.
    expect(report.warnings.grep(/#{Regexp.escape(archived_email)}/)).to eq([
      "usuário #{archived_email} não encontrado nesta base; registros descartados: #{dropped.join(", ")}",
    ])
  end

  it "refuses to create Ruby/ERB code this database doesn't know" do
    Admissions::FormField.disable_erb_validation! do
      FactoryBot.build(:form_field, form_template: form_template, name: "Calculado",
        field_type: Admissions::FormField::CODE,
        configuration: { "template_type" => "Ruby", "code" => "1 + 1" }.to_json).save!(validate: false)
    end
    zip
    purge_everything

    report = import(zip)

    expect(report.errors.first).to include("Calculado")
    expect(Admissions::AdmissionProcess.count).to eq(0)
  end

  # refuse_duplicate! procura o id original, mas a importacao cria ids novos:
  # reenviar o formulario (F5 na pagina do relatorio) importa uma segunda copia.
  it "refuses to import the same archive twice" do
    zip
    purge_process
    import(zip)

    report = import(zip)

    expect(report.errors).not_to be_empty
    expect(Admissions::AdmissionProcess.count).to eq(1)
  end

  # A exportacao escreve o valor como esta, e a importacao trata qualquer celula
  # que comece pela sentinela como ponteiro para files/long_values/.
  it "restores an answer that starts with the long value sentinel" do
    answer = "#{Admissions::AdmissionExportHelper::LONG_VALUE_SENTINEL}resposta do candidato"
    application.filled_form.fields.find_by(form_field: text_field).update_column(:value, answer)
    zip
    purge_process

    report = import(zip)

    expect(report.errors).to be_empty
    expect(imported_application.filled_form.fields.find_by(form_field: text_field).value).to eq(answer)
  end

  # A exportacao colhe as fases so de process.phases; uma fase desvinculada do
  # edital depois de ter resultados fica fora do arquivo.
  it "restores the results of a phase unlinked from the process" do
    process_phase.destroy!
    zip
    purge_process

    report = import(zip)

    expect(report.errors).to be_empty
    expect(imported_application.results.first.admission_phase_id).to eq(phase.id)
  end

  it "writes nothing on a dry run" do
    zip
    purge_process
    before = counts

    report = import(zip, dry_run: true)

    expect(report.errors).to be_empty
    expect(report.created["admission_applications"]).to eq(2)
    expect(counts).to eq(before)
    expect(storage.count).to eq(0)
  end

  it "generates a new token when the archived one is taken" do
    zip
    token = application.token
    purge_process
    FactoryBot.create(:admission_application, token: token, email: "outra@example.com")

    report = import(zip)

    expect(report.errors).to be_empty
    expect(imported_application.token).to be_present
    expect(imported_application.token).not_to eq(token)
    expect(report.warnings.join).to include("token")
  end

  describe "invalid archives" do
    it "rejects a zip without edital.xlsx" do
      broken = rewrite_zip(zip) { |name, bytes| bytes unless name == "edital.xlsx" }
      expect(import(broken).errors.first).to include("edital.xlsx")
    end

    it "rejects something that isn't a zip" do
      expect(import("not a zip").errors).not_to be_empty
    end

    it "rejects another format version" do
      zip
      stub_const("Admissions::AdmissionImportHelper::FORMAT_VERSION", 99)
      purge_process
      expect(import(zip).errors.first).to include("versão")
    end

    it "rejects a file whose content doesn't match its hash" do
      tampered = rewrite_zip(zip) { |name, bytes| name.start_with?("files/#{medium_hash}") ? "outro".b : bytes }
      purge_process
      report = import(tampered)
      expect(report.errors.first).to include("corrompido")
      expect(Admissions::AdmissionProcess.count).to eq(0)
    end
  end
end

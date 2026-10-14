# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Formulário preenchido (#681): a consolidação, que calcula os campos de código
# e dispara os de e-mail a partir dos campos do candidato; a sincronização de
# campos com os atributos da candidatura; e os utilitários que as telas usam.
RSpec.describe Admissions::FilledForm, "consolidação e sincronização", type: :model do
  before(:each) do
    @template = create_admission_template("Inscrição", {
      "nota" => Admissions::FormField::NUMBER,
      "nome" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_NAME },
      "email" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_EMAIL },
      "cpf" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "cpf" } },
      "foto" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "photo" } },
      "anexo" => Admissions::FormField::FILE,
    })
    @process = create_closed_admission_process(@template, simple_url: "filled-form-spec")
  end

  describe "#consolidate" do
    before(:each) do
      @consolidation = create_consolidation_template("Consolidação", {
        "dobro" => code_field("{{ fields.nota | times: 2 }}"),
        "texto" => code_field("{{ application.name }} em {{ process.title }}", code_type: "string"),
        "condicional" => code_field(
          "99",
          condition: { "mode" => Admissions::FormCondition::CONDITION, "field" => "nota",
                       "condition" => Admissions::FormCondition::GE, "value" => "9" }
        ),
        "aviso" => {
          field_type: Admissions::FormField::EMAIL,
          configuration: {
            "to" => "{{ application.email }}",
            "subject" => "Resultado de {{ application.name }}",
            "body" => "Sua nota foi {{ fields.nota }} <b>{{ fields.dobro }}</b>",
            "template_type" => Admissions::FormField::LIQUID,
          },
        },
      })
      @application = create_application(@process, name: "Ana", fields: { "nota" => "8" })
      @filled = Admissions::FilledForm.new(is_filled: false, form_template: @consolidation)
      @vars = { process: @process, application: @application }
      allow(Notifier).to receive(:send_emails)
    end

    it "calcula cada campo de código e devolve o valor convertido no mapa de campos" do
      field_objects = @application.fields_hash
      @filled.consolidate(field_objects: field_objects, vars: @vars)

      values = @filled.fields.index_by { |field| field.form_field.name }
      expect(values["dobro"].value).to eq("16")
      expect(values["texto"].value).to eq("Ana em #{@process.title}")
      expect(field_objects["dobro"]).to eq(values["dobro"])
      # O mapa de valores simples que segue para os próximos campos já vem
      # convertido: "16" virou número.
      expect(@vars[:fields]["dobro"]).to eq(16.0)
      expect(@vars[:fields]["nota"]).to eq("8")
    end

    it "pula o campo cuja condição não é satisfeita" do
      @filled.consolidate(field_objects: @application.fields_hash, vars: @vars)
      skipped = @filled.fields.find { |field| field.form_field.name == "condicional" }
      expect(skipped.value).to eq(
        I18n.t("activerecord.errors.models.admissions/filled_form_field.consolidation.skip")
      )
    end

    it "envia o e-mail montado pelo template e guarda o que enviou" do
      @filled.consolidate(field_objects: @application.fields_hash, vars: @vars)

      expect(Notifier).to have_received(:send_emails).with(notifications: [{
        to: @application.email,
        subject: "Resultado de Ana",
        body: "Sua nota foi 8 <b>16.0</b>",
      }])
      sent = @filled.fields.find { |field| field.form_field.name == "aviso" }
      expect(sent.value).to include("Para: #{@application.email}")
      expect(sent.value).to include("Assunto: Resultado de Ana")
    end

    it "estoura quando a condição de um campo usa campo inexistente" do
      FactoryBot.create(:form_field, name: "sumido")
      @consolidation.fields.find_by(name: "condicional").update!(
        configuration: JSON.dump(code_field(
          "1", condition: { "mode" => Admissions::FormCondition::CONDITION, "field" => "sumido",
                            "condition" => Admissions::FormCondition::NOT_NULL }
        )[:configuration])
      )
      expect {
        @filled.consolidate(field_objects: @application.fields_hash, vars: @vars)
      }.to raise_error(Exceptions::MissingFieldException, /sumido/)
    end

    it "mantém o que já estava consolidado e descarta campo que saiu do template" do
      @filled.save!
      old_field = FactoryBot.create(:form_field, form_template: @consolidation, name: "antigo", field_type: Admissions::FormField::CODE,
        configuration: JSON.dump(code_field("1")[:configuration]))
      FactoryBot.create(:filled_form_field, filled_form: @filled, form_field: old_field, value: "1")
      existing = FactoryBot.create(
        :filled_form_field, filled_form: @filled,
        form_field: @consolidation.fields.find_by(name: "dobro"), value: "1000"
      )
      old_field.filled_fields.delete_all
      old_field.destroy!

      field_objects = @application.fields_hash
      @filled.consolidate(field_objects: field_objects, vars: @vars)

      expect(@filled.fields.where(form_field_id: old_field.id)).to be_empty
      expect(field_objects["dobro"]).to eq(existing)
      expect(@vars[:fields]["dobro"]).to eq("1000")
    end

    it "funciona sem mapa de campos e sem variáveis" do
      empty = Admissions::FilledForm.new(
        is_filled: false,
        form_template: create_consolidation_template("Vazia", { "um" => code_field("1") })
      )
      empty.consolidate
      expect(empty.fields.first.value).to eq("1")
    end
  end

  describe "sincronização com a candidatura" do
    it "sync_fields_before copia nome e e-mail da candidatura para os campos" do
      application = create_application(@process, name: "Ana", email: "ana@example.com", fields: { "nome" => "x", "email" => "y" })
      application.filled_form.sync_fields_before(application)
      values = application.filled_form.fields.index_by { |field| field.form_field.name }
      expect(values["nome"].value).to eq("Ana")
      expect(values["email"].value).to eq("ana@example.com")
    end

    it "sync_fields_after leva os campos de volta para a candidatura" do
      application = create_application(@process, name: "Ana", fields: { "nome" => "Ana Maria", "email" => "nova@example.com" })
      application.filled_form.sync_fields_after(application)
      expect(application.name).to eq("Ana Maria")
      expect(application.email).to eq("nova@example.com")
    end
  end

  describe "utilitários" do
    it "to_label diz se está preenchido" do
      filled = FactoryBot.build(:filled_form, form_template: @template, is_filled: true)
      expect(filled.to_label).to eq(I18n.t(
        "activerecord.attributes.admissions/filled_form.filled_status.filled", form: "Inscrição"
      ))
      filled.is_filled = false
      expect(filled.to_label).to eq(I18n.t(
        "activerecord.attributes.admissions/filled_form.filled_status.not_filled", form: "Inscrição"
      ))
    end

    it "prepare_missing_fields constrói só os campos que faltam" do
      application = create_application(@process, fields: { "nota" => "8" })
      application.filled_form.prepare_missing_fields
      expect(application.filled_form.fields.size).to eq(@template.fields.count)
      expect(application.filled_form.fields.count(&:new_record?)).to eq(@template.fields.count - 1)
    end

    it "find_cpf_field acha o campo de aluno configurado como CPF" do
      application = create_application(@process, fields: { "cpf" => "123", "nota" => "8" })
      expect(application.filled_form.find_cpf_field.value).to eq("123")
      other = create_application(@process, fields: { "nota" => "8" })
      expect(other.filled_form.find_cpf_field).to be_nil
    end

    it "erase_non_filled_file_fields descarta o arquivo dos campos novos e recarrega os gravados" do
      application = create_application(@process, fields: { "nota" => "8" })
      filled = application.filled_form
      stored = FactoryBot.create(
        :filled_form_field, filled_form: filled, form_field: @template.fields.find_by(name: "anexo"),
        value: nil, file: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png")
      )
      filled.reload
      stored_in_memory = filled.fields.find { |field| field.id == stored.id }
      stored_in_memory.value = "mexido"
      built = filled.fields.new(
        form_field: @template.fields.find_by(name: "foto"),
        file: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png")
      )
      expect(built.file).to be_present

      filled.erase_non_filled_file_fields

      expect(built.file).to be_blank
      expect(stored_in_memory.value).to be_nil
      expect(stored_in_memory.file).to be_present
    end
  end
end

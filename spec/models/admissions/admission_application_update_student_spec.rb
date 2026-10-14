# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Cópia da candidatura para o aluno (#681): cada tipo de campo de aluno que o
# formulário pode declarar (atributo simples, foto, endereço, cidade, cidade de
# nascimento, formações), com o registro do que mudou na observação do aluno; e
# a atribuição dos formulários enviados pela tela (assign_form), que marca como
# preenchido o que veio e resolve a pendência correspondente.
RSpec.describe Admissions::AdmissionApplication, "cópia para o aluno e envio de formulários", type: :model do
  def png
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png")
  end

  describe "#update_student" do
    before(:each) do
      @template = create_admission_template("Inscrição", {
        "nome" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_NAME },
        "cpf" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "cpf" } },
        "foto" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "photo" } },
        "endereco" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "special_address" } },
        "cidade" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "special_city" } },
        "nascimento" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "special_birth_city" } },
        "formacao" => { field_type: Admissions::FormField::STUDENT_FIELD,
                        configuration: { "field" => "special_majors", "values" => ["Graduação"], "statuses" => ["Completo"] } },
        "livre" => Admissions::FormField::STRING,
      })
      @process = create_closed_admission_process(@template, simple_url: "update-student-spec")
      @country = FactoryBot.create(:country, name: "Brasil")
      @state = FactoryBot.create(:state, name: "Rio de Janeiro", code: "RJ", country: @country)
      @city = FactoryBot.create(:city, name: "Niterói", state: @state)
      @institution = FactoryBot.create(:institution, name: "UFF")
      @level = FactoryBot.create(:level, name: "Graduação")
      @major = FactoryBot.create(:major, name: "Computação", institution: @institution, level: @level)
    end

    it "copia os campos simples, os lugares e as formações para um aluno novo" do
      application = create_application(@process, name: "Ana", email: "ana@example.com", fields: {
        "nome" => "Ana Maria", "cpf" => "123.456.789-00",
        "endereco" => "Rua A <$> 10 <$> apto 2",
        "cidade" => "Niterói <$> RJ <$> Brasil",
        "nascimento" => "Niterói <$> RJ <$> Brasil",
      })
      formacao = application.filled_form.fields.find { |field| field.form_field.name == "formacao" } ||
        FactoryBot.create(:filled_form_field, filled_form: application.filled_form,
          form_field: @template.fields.find_by(name: "formacao"), value: nil)
      formacao.scholarities.create!(level: "Graduação", status: "Completo", institution: "UFF", course: "Computação")
      student = Student.new

      application.reload.update_student(student)

      expect(student.name).to eq("Ana Maria")
      expect(student.email).to eq("ana@example.com")
      expect(student.cpf).to eq("123.456.789-00")
      expect(student.address).to eq("Rua A, 10, apto 2")
      expect(student.city).to eq(@city)
      expect(student.birth_city).to eq(@city)
      expect(student.birth_state).to eq(@state)
      expect(student.birth_country).to eq(@country)
      expect(student.student_majors.map(&:major)).to eq([@major])
      expect(student.obs).to be_nil
    end

    it "anota na observação cada valor que mudou e cada lugar ou curso que não achou" do
      application = create_application(@process, name: "Ana", email: "nova@example.com", fields: {
        "nome" => "Ana Maria", "cpf" => "999",
        "cidade" => "Atlântida <$> ZZ <$> Nenhures",
        "nascimento" => "Atlântida <$> RJ <$> Brasil",
      })
      formacao = FactoryBot.create(:filled_form_field, filled_form: application.filled_form,
        form_field: @template.fields.find_by(name: "formacao"), value: nil)
      formacao.scholarities.create!(level: "Graduação", status: "Completo", institution: "Outra", course: "Física")
      student = FactoryBot.create(:student, name: "Ana Antiga", email: "antiga@example.com", cpf: "111", obs: "Nota prévia")

      application.reload.update_student(student)

      expect(student.name).to eq("Ana Maria")
      expect(student.birth_city).to be_nil
      expect(student.birth_state).to eq(@state)
      expect(student.birth_country).to eq(@country)
      expect(student.obs).to start_with("Nota prévia\nCandidatura #{application.to_label}: \n- ")
      expect(student.obs).to include("cidade/Cidade de candidatura não encontrada: Atlântida, ZZ, Nenhures")
      expect(student.obs).to include("nascimento/Cidade de candidatura não encontrada: Atlântida, RJ, Brasil")
      expect(student.obs).to include("formacao/Curso não encontrado: Graduação - Completo - Outra - Física")
      expect(student.obs).to include("#{Student.record_i18n_attr("cpf")} alterado. Valor anterior: 111")
      expect(student.obs).to include("#{Student.record_i18n_attr("name")} alterado. Valor anterior: Ana Antiga")
      expect(student.obs).to include("#{Student.record_i18n_attr("email")} alterado. Valor anterior: antiga@example.com")
    end

    it "não repete formação que o aluno já tem" do
      application = create_application(@process)
      formacao = FactoryBot.create(:filled_form_field, filled_form: application.filled_form,
        form_field: @template.fields.find_by(name: "formacao"), value: nil)
      formacao.scholarities.create!(level: "Graduação", status: "Completo", institution: "UFF", course: "Computação")
      student = FactoryBot.create(:student)
      student.student_majors.create!(major: @major)

      application.reload.update_student(student)
      expect(student.student_majors.size).to eq(1)
    end

    it "usa o nome e o e-mail da candidatura quando o formulário não os sincroniza" do
      plain = create_admission_template("Simples", { "x" => Admissions::FormField::STRING })
      process = create_closed_admission_process(plain, simple_url: "update-student-plain")
      application = create_application(process, name: "Bia", email: "bia@example.com")
      student = Student.new
      application.update_student(student)
      expect(student.name).to eq("Bia")
      expect(student.email).to eq("bia@example.com")
    end

    it "deixa o campo de aluno nome ou e-mail do formulário valer sobre a sincronização" do
      explicit = create_admission_template("Explícito", {
        "nome_aluno" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "name" } },
        "email_aluno" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "email" } },
      })
      process = create_closed_admission_process(explicit, simple_url: "update-student-explicit")
      application = create_application(process, name: "Bia", email: "bia@example.com",
        fields: { "nome_aluno" => "Beatriz", "email_aluno" => "beatriz@example.com" })
      student = Student.new
      application.update_student(student)
      expect(student.name).to eq("Beatriz")
      expect(student.email).to eq("beatriz@example.com")
    end

    it "copia a foto e guarda o link da anterior quando troca" do
      application = create_application(@process, fields: { "foto" => { file: png } })
      student = FactoryBot.create(:student)
      application.update_student(student)
      expect(student.photo.file).to be_present
      first_hash = student.photo.medium_hash
      student.save!

      # Outra foto, com bytes diferentes: o identificador vem do conteúdo.
      other = Tempfile.new(["outra", ".png"])
      other.binmode
      other.write(File.binread(Rails.root.join("spec/fixtures/user.png")) + "\n")
      other.rewind
      second = create_application(@process, fields: {
        "foto" => { file: Rack::Test::UploadedFile.new(other.path, "image/png") },
      })
      second.update_student(student)

      expect(student.photo.medium_hash).not_to eq(first_hash)
      expect(student.obs).to include("foto/Foto alterada. Foto anterior: ")
      expect(student.obs).to include(first_hash)
    end

    it "com only_photo troca a foto sem anotar nada" do
      application = create_application(@process, fields: { "foto" => { file: png } })
      student = FactoryBot.create(:student)
      application.update_student(student, only_photo: true)
      expect(student.photo.file).to be_present
      expect(student.obs).to be_nil
    end

    it "com only_photo ignora todo o resto" do
      application = create_application(@process, fields: { "nome" => "Ana Maria", "cpf" => "123" })
      student = Student.new(name: "Antiga")
      application.update_student(student, only_photo: true)
      expect(student.name).to eq("Antiga")
      expect(student.cpf).to be_nil
    end

    it "estoura quando o formulário declara um campo de aluno que não existe" do
      broken = create_admission_template("Quebrado", {
        "x" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "inexistente" } },
      })
      process = create_closed_admission_process(broken, simple_url: "update-student-broken")
      application = create_application(process, fields: { "x" => "1" })
      expect { application.update_student(Student.new) }.to raise_error(
        Exceptions::InvalidStudentFieldException, /inexistente/
      )
    end
  end

  describe "#assign_form" do
    before(:each) do
      @template = create_admission_template("Inscrição", {
        "nome" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_NAME },
        "nota" => Admissions::FormField::NUMBER,
      })
      @letters = create_admission_template(
        "Carta", { "texto" => Admissions::FormField::TEXT },
        template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
      )
      @process = create_closed_admission_process(
        @template, simple_url: "assign-form-spec", letter_template: @letters,
        end_date: Date.today + 5.days, edit_date: Date.today + 10.days
      )
      @application = create_application(@process, name: "Ana", filled: false, fields: { "nota" => "5" })
      @nota = @application.filled_form.fields.first
    end

    # O que a tela manda: um registro por campo do template, com id quando o
    # campo já existe e só form_field_id quando é novo.
    def filled_form_params(filled_form, values, enable: "1")
      existing = filled_form.fields.index_by(&:form_field_id)
      fields = filled_form.form_template.fields.each_with_index.to_h do |form_field, index|
        attrs = { form_field_id: form_field.id, value: values[form_field.name] }
        attrs[:id] = existing[form_field.id].id if existing[form_field.id]
        [index.to_s, attrs]
      end
      { id: filled_form.id, enable_submission: enable, fields_attributes: fields }
    end

    def value_of(filled_form, name)
      filled_form.fields.find { |field| field.form_field.name == name }.value
    end

    it "marca a inscrição como enviada e sincroniza o nome quando a submissão está habilitada" do
      @application.assign_form({
        filled_form_attributes: filled_form_params(@application.filled_form, { "nota" => "9", "nome" => "Ana Maria" }),
      })
      expect(@application.filled_form.is_filled).to be true
      expect(value_of(@application.filled_form, "nota")).to eq("9")
      expect(@application.name).to eq("Ana Maria")
      expect(@application).to be_valid
    end

    it "não marca como enviada quando a submissão não veio habilitada" do
      @application.assign_form({
        filled_form_attributes: filled_form_params(@application.filled_form, { "nota" => "9", "nome" => "Ana" }, enable: "0"),
      })
      expect(@application.filled_form.is_filled).to be false
      expect(value_of(@application.filled_form, "nota")).to eq("9")
    end

    it "desfaz a marcação de enviado quando a candidatura fica inválida" do
      @process.update!(min_letters: 2, max_letters: 2)
      @application.assign_form({
        filled_form_attributes: filled_form_params(@application.filled_form, { "nota" => "9", "nome" => "Ana" }),
      })
      expect(@application.filled_form.is_filled).to be false
      expect(@application.errors[:base]).not_to be_empty
    end

    it "marca as cartas enviadas com submissão habilitada, e só elas" do
      @process.update!(min_letters: 1, max_letters: 2)
      sent = @application.letter_requests.create!(name: "Prof. A", email: "a@example.com")
      kept = @application.letter_requests.create!(name: "Prof. B", email: "b@example.com")
      @application.reload.assign_form({
        letter_requests_attributes: {
          "0" => { id: sent.id, filled_form_attributes: filled_form_params(sent.filled_form, {}) },
          "1" => { id: kept.id, filled_form_attributes: filled_form_params(kept.filled_form, {}, enable: "0") },
        },
      }, has_letter_forms: true)
      letters = @application.letter_requests.index_by(&:id)
      expect(letters[sent.id].filled_form.is_filled).to be true
      expect(letters[kept.id].filled_form.is_filled).to be false
    end

    context "com fase" do
      before(:each) do
        @shared = create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING })
        @phase = add_phase(@process, 1, name: "Análise", shared_form: @shared)
        @reviewer = professor_user("assign-reviewer@ic.uff.br")
        add_committee(@phase, [@reviewer])
        @application.filled_form.update!(is_filled: true)
        @application.update!(admission_phase: @phase)
        @phase.create_pendencies_for_candidate(@application)
        @pendency = @application.pendencies.find_by(mode: Admissions::AdmissionPendency::SHARED, user: @reviewer)
        expect(@pendency.status).to eq(Admissions::AdmissionPendency::PENDENT)
      end

      it "grava o formulário compartilhado enviado pelo comitê e resolve a pendência" do
        @application.assign_form({
          results_attributes: {
            "0" => {
              mode: Admissions::AdmissionPhaseResult::SHARED, admission_phase_id: @phase.id,
              filled_form_attributes: {
                enable_submission: "1", form_template_id: @shared.id,
                fields_attributes: { "0" => { form_field_id: @shared.fields.first.id, value: "aprovar" } },
              },
            },
          },
        }, has_phases: true, committee_permission_user: @reviewer)

        result = @application.results.find { |r| r.mode == Admissions::AdmissionPhaseResult::SHARED }
        expect(result.filled_form.is_filled).to be true
        expect(result.filled_form.fields.first.value).to eq("aprovar")
        expect(@pendency.reload.status).to eq(Admissions::AdmissionPendency::OK)
      end

      it "não resolve pendência de formulário que a tela não permitia editar" do
        later = add_phase(@process, 2, name: "Entrevista")
        @application.update!(admission_phase: later)
        @application.assign_form({
          results_attributes: {
            "0" => {
              mode: Admissions::AdmissionPhaseResult::SHARED, admission_phase_id: @phase.id,
              filled_form_attributes: {
                enable_submission: "1", form_template_id: @shared.id,
                fields_attributes: { "0" => { form_field_id: @shared.fields.first.id, value: "tarde" } },
              },
            },
          },
        }, has_phases: true)
        expect(@pendency.reload.status).to eq(Admissions::AdmissionPendency::PENDENT)
      end

      it "não marca o formulário de fase que não veio na submissão" do
        @application.assign_form({ name: "Ana" }, has_phases: true)
        expect(@application.results.none? { |r| r.filled_form.is_filled }).to be true
        expect(@pendency.reload.status).to eq(Admissions::AdmissionPendency::PENDENT)
      end
    end

    it "aceita a edição do ranking pela tela com can_edit_override" do
      ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
      FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: ranking, order: 1)
      result = Admissions::AdmissionRankingResult.create!(admission_application: @application, ranking_config: ranking)
      result.filled_form.update!(is_filled: true)
      position = result.filled_position
      position.update!(value: "2")
      @application.reload

      @application.assign_form({
        rankings_attributes: { "0" => { id: result.id, filled_form_attributes: {
          id: result.filled_form.id, enable_submission: "1",
          fields_attributes: { "0" => { id: position.id, value: "1" } },
        } } },
      }, has_rankings: true, can_edit_override: true)
      @application.save!

      expect(position.reload.value).to eq("1")
      expect(result.reload.filled_form.is_filled).to be true
    end
  end
end

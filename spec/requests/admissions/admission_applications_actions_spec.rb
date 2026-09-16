# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Ações da lista de candidaturas (#681): cancelar, desfazer consolidação,
# abrir a edição com override, gravar formulários de fase pela edição, e os
# filtros e a ordenação por situação que a busca oferece.
RSpec.describe "Admissions::AdmissionApplications: ações e busca", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "applications_admin@ic.uff.br")
    sign_in @admin

    @template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(@template, simple_url: "applications-request")
    @shared = create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING })
    @phase1 = add_phase(@process, 1, name: "Análise", shared_form: @shared)
    @phase2 = add_phase(@process, 2, name: "Entrevista")
    @reviewer = professor_user("applications-reviewer@ic.uff.br")
    add_committee(@phase1, [@reviewer])
    @application = create_application(@process, name: "Ana", fields: { "nota" => "8" }, admission_phase: @phase1)
    @phase1.create_pendencies_for_candidate(@application)
  end

  describe "PUT cancel" do
    it "cancela a candidatura e recarrega a lista" do
      put cancel_admission_application_path(@application), xhr: true
      expect(response).to have_http_status(:ok)
      expect(@application.reload.status).to eq(Admissions::AdmissionApplication::CANCELED)
      expect(response.body).to include(I18n.t("active_scaffold.admissions/admission_application.cancel.success"))
    end

    it "não mexe em candidatura já cancelada e responde por html e iframe" do
      @application.update!(status: Admissions::AdmissionApplication::CANCELED, status_message: "antes")
      put cancel_admission_application_path(@application)
      expect(response).to have_http_status(:redirect)
      expect(@application.reload.status_message).to eq("antes")

      put cancel_admission_application_path(@application), params: { iframe: true }
      expect(response.body).to include("parent")
    end

    it "é negado a quem não pode cancelar" do
      sign_out @admin
      sign_in @reviewer
      put cancel_admission_application_path(@application), xhr: true
      expect(response).not_to have_http_status(:ok)
      expect(@application.reload.status).to be_nil
    end
  end

  describe "PUT undo_consolidation" do
    it "volta a candidatura para a fase anterior" do
      @application.update!(admission_phase: @phase2)
      put undo_consolidation_admission_application_path(@application), xhr: true
      expect(response).to have_http_status(:ok)
      expect(@application.reload.admission_phase).to eq(@phase1)
      expect(response.body).to include(I18n.t(
        "active_scaffold.admissions/admission_application.undo_consolidation.success", name: "Análise"
      ))
    end

    it "ignora candidatura ainda na inscrição e respeita staff_can_undo" do
      fresh = create_application(@process, name: "Bia")
      put undo_consolidation_admission_application_path(fresh)
      expect(response).to have_http_status(:redirect)
      expect(fresh.reload.admission_phase).to be_nil

      @process.update!(staff_can_undo: false)
      put undo_consolidation_admission_application_path(@application), params: { iframe: true }
      expect(response.body).to include("parent")
      expect(@application.reload.admission_phase).to eq(@phase1)
    end
  end

  describe "configuração e edição" do
    it "abre e fecha os itens de configuração avançada" do
      get configuration_admission_application_path(@application), xhr: true
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("advanced-config-item")

      get configure_all_admission_applications_path, xhr: true
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("advanced-config-item")
    end

    it "abre a edição com override para quem pode, com o formulário de fase" do
      get edit_admission_application_path(@application, override: true), xhr: true
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Análise")
    end

    it "grava o formulário compartilhado enviado pela edição e resolve a pendência" do
      pendency = @application.pendencies.find_by(mode: Admissions::AdmissionPendency::SHARED, user: @reviewer)
      expect(pendency.status).to eq(Admissions::AdmissionPendency::PENDENT)

      put admission_application_path(@application), params: {
        can_edit_override: "1",
        record: {
          results_attributes: {
            "0" => {
              mode: Admissions::AdmissionPhaseResult::SHARED, admission_phase_id: @phase1.id,
              filled_form_attributes: {
                enable_submission: "1", form_template_id: @shared.id,
                fields_attributes: { "0" => { form_field_id: @shared.fields.first.id, value: "aprovar" } },
              },
            },
          },
        },
      }, xhr: true

      expect(response).to have_http_status(:ok)
      result = @application.results.find_by(mode: Admissions::AdmissionPhaseResult::SHARED)
      expect(result.filled_form.is_filled).to be true
      expect(result.filled_form.fields.first.value).to eq("aprovar")
      expect(pendency.reload.status).to eq(Admissions::AdmissionPendency::OK)
    end

    it "deixa o membro do comitê gravar a própria avaliação" do
      @phase1.update!(member_form: create_admission_template("Parecer", { "parecer" => Admissions::FormField::STRING }))
      Admissions::AdmissionPhase.find(@phase1.id).create_pendencies_for_candidate(@application)
      pendency = @application.pendencies.find_by(mode: Admissions::AdmissionPendency::MEMBER, user: @reviewer)
      sign_out @admin
      sign_in @reviewer

      put admission_application_path(@application), params: {
        record: {
          evaluations_attributes: {
            "0" => {
              user_id: @reviewer.id, admission_phase_id: @phase1.id,
              filled_form_attributes: {
                enable_submission: "1", form_template_id: @phase1.member_form.id,
                fields_attributes: { "0" => { form_field_id: @phase1.member_form.fields.first.id, value: "forte" } },
              },
            },
          },
        },
      }, xhr: true

      expect(response).to have_http_status(:ok)
      evaluation = @application.evaluations.find_by(user: @reviewer)
      expect(evaluation.filled_form.is_filled).to be true
      expect(pendency.reload.status).to eq(Admissions::AdmissionPendency::OK)
    end

    it "não deixa editar candidatura já decidida" do
      @application.update!(status: Admissions::AdmissionApplication::APPROVED)
      sign_out @admin
      sign_in @reviewer
      get edit_admission_application_path(@application), xhr: true
      expect(response.body).to include("Acesso inválido")
    end
  end

  describe "busca e ordenação" do
    before(:each) do
      @unsent = create_application(@process, name: "Bia", filled: false)
      @student = FactoryBot.create(:student)
      @mapped = create_application(@process, name: "Caio", student: @student)
      @enrolled = create_application(
        @process, name: "Dora", student: FactoryBot.create(:student),
        enrollment: FactoryBot.create(:enrollment), status: Admissions::AdmissionApplication::APPROVED
      )
    end

    def search(**params)
      get admission_applications_path, params: { search: params }
      expect(response).to have_http_status(:ok)
      Nokogiri::HTML(response.body).css("tr.record").filter_map { |row| row["id"] }
    end

    def row_id(application)
      "as_admissions__admission_applications-list-#{application.id}-row"
    end

    it "filtra por inscrição enviada" do
      yes = I18n.t("activerecord.attributes.admissions/admission_application.is_filled_options.true")
      no = I18n.t("activerecord.attributes.admissions/admission_application.is_filled_options.false")
      expect(search(is_filled: yes)).to contain_exactly(row_id(@application), row_id(@mapped), row_id(@enrolled))
      expect(search(is_filled: no)).to contain_exactly(row_id(@unsent))
    end

    it "filtra por pendência" do
      yes = I18n.t("activerecord.attributes.admissions/admission_application.pendency_options.true")
      no = I18n.t("activerecord.attributes.admissions/admission_application.pendency_options.false")
      expect(search(pendency: yes)).to contain_exactly(row_id(@application))
      expect(search(pendency: no)).to contain_exactly(row_id(@unsent), row_id(@mapped), row_id(@enrolled))
    end

    it "filtra por situação: valor fixo, pendente para o usuário e sem pendência para o usuário" do
      expect(search(status: Admissions::AdmissionApplication::APPROVED)).to contain_exactly(row_id(@enrolled))
      expect(search(status: @reviewer.id.to_s)).to contain_exactly(row_id(@application))
      expect(search(status: (-@reviewer.id).to_s)).to contain_exactly(row_id(@unsent), row_id(@mapped))
    end

    it "filtra por vínculo com aluno e matrícula" do
      expect(search(mapping: "student")).to contain_exactly(row_id(@mapped), row_id(@enrolled))
      expect(search(mapping: "enrollment")).to contain_exactly(row_id(@enrolled))
      expect(search(mapping: "student_no_enrollment")).to contain_exactly(row_id(@mapped))
      expect(search(mapping: "outro").size).to eq(4)
    end

    it "mostra o vínculo com aluno e matrícula na coluna de situação" do
      get admission_applications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Com matrícula")
      expect(response.body).to include("Com aluno")
    end

    it "mostra a situação descritiva na visão simples" do
      get admission_applications_path, params: { simple_view: "1" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pronto para consolidação").or include("Pendente")
    end
  end
end

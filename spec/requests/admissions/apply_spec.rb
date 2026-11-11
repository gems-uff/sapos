# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admissions::ApplyController", type: :request do
  before(:each) do
    @template = FactoryBot.create(:form_template, name: "Inscrição")
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2", simple_url: "mestrado-2026-2",
      form_template: @template,
      start_date: Date.current - 10.days,
      end_date: Date.current + 10.days,
      edit_date: Date.current + 20.days
    )
    @application = FactoryBot.create(
      :admission_application, admission_process: @process,
      filled_form: FactoryBot.create(
        :filled_form, form_template: @template, is_filled: true
      )
    )
  end

  describe "PUT update without the record parameter" do
    # O PUT chega só com _method, authenticity_token e commit — upload
    # interrompido, duplo clique em "Modificar inscrição". O candidato não deve
    # levar 500 por isso.
    it "keeps the candidate on the application with a message" do
      put admission_apply_path(
        admission_id: @process.simple_id, id: @application.token
      ), params: { commit: "Modificar inscrição" }

      expect(response).to redirect_to(admission_apply_path(
        admission_id: @process.simple_id, id: @application.token
      ))
      expect(flash[:alert]).to eq I18n.t("errors.admissions.empty_submission")
    end

    it "does not touch the application" do
      expect {
        put admission_apply_path(
          admission_id: @process.simple_id, id: @application.token
        ), params: { commit: "Modificar inscrição" }
      }.not_to change { @application.reload.updated_at }
    end
  end

  describe "POST create without the record parameter" do
    it "sends the candidate back to the empty form with a message" do
      post admission_apply_index_path(admission_id: @process.simple_id),
        params: { commit: "Enviar inscrição" }

      expect(response).to redirect_to(
        new_admission_apply_path(admission_id: @process.simple_id)
      )
      expect(flash[:alert]).to eq I18n.t("errors.admissions.empty_submission")
    end
  end

  describe "e-mail sincronizado do formulário" do
    before(:each) do
      @email_field = FactoryBot.create(
        :form_field, form_template: @template, name: "E-mail",
        field_type: Admissions::FormField::STRING,
        sync: Admissions::FormField::SYNC_EMAIL
      )
    end

    it "renders the synchronized field as an email input" do
      get new_admission_apply_path(admission_id: @process.simple_id)

      expect(response.body).to include('type="email"')
    end

    it "rejects an invalid synchronized email on the server" do
      expect {
        post admission_apply_index_path(admission_id: @process.simple_id), params: {
          record: {
            name: "Ana", email: "ana@example.com",
            filled_form_attributes: {
              enable_submission: "1",
              fields_attributes: {
                "0" => { form_field_id: @email_field.id, value: "nao-e-mail" }
              }
            }
          }
        }
      }.not_to change { Admissions::AdmissionApplication.count }

      expect(response).to have_http_status(:ok)
    end
  end
end

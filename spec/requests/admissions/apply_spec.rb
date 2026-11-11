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

  # O que a tela manda e sempre o formulario da inscricao. O que chega de outro
  # jeito nao veio da tela: nao pode virar pagina de erro, nem inscricao dada
  # como realizada sem passar pelo que o formulario exige.
  describe "PUT update with a record that the screen does not send" do
    before(:each) do
      FactoryBot.create(
        :form_field, form_template: @template, name: "Campo obrigatorio",
        configuration: { required: true }.to_json
      )
      @application.filled_form.update!(is_filled: false)
    end

    def send_raw(params)
      put admission_apply_path(admission_id: @process.simple_id, id: @application.token),
        params: params, env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
    end

    {
      "a loose text" => { record: "abc" },
      "a list" => { record: ["abc"] },
    }.each do |shape, params|
      it "keeps the candidate on the application with a message, when the record is #{shape}" do
        send_raw(params)

        expect(response).to redirect_to(admission_apply_path(
          admission_id: @process.simple_id, id: @application.token
        ))
        expect(flash[:alert]).to eq I18n.t("errors.admissions.empty_submission")
        expect(@application.reload.filled_form.is_filled).to be(false)
      end
    end

    {
      "a list in the place of the fields of the form" => { record: { filled_form_attributes: ["abc"] } },
      "the fields of the form in a shape that the screen does not send" =>
        { record: { filled_form_attributes: { enable_submission: { a: "1" } } } },
      "no field of the form" => { record: { x: "" } },
      "the submission of the form turned off" => { record: { filled_form_attributes: { enable_submission: "0" } } },
    }.each do |shape, params|
      it "checks the form as the screen would send it, with #{shape}" do
        allow(ExceptionNotifier).to receive(:notify_exception)
        filled_form_id = @application.filled_form_id

        send_raw(params)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Campo obrigatorio")
        expect(@application.reload.filled_form.is_filled).to be(false)
        expect(@application.filled_form_id).to eq(filled_form_id)
        expect(@application.submission_time).to be_nil
      end
    end

    # Control: the same form, with the required field filled, is accepted.
    it "accepts the form that the screen sends" do
      field = @template.fields.find_by!(name: "Campo obrigatorio")

      send_raw(record: { filled_form_attributes: {
        id: @application.filled_form_id, enable_submission: "1",
        fields_attributes: { "0" => { form_field_id: field.id, value: "preenchido" } },
      } })

      expect(response).to redirect_to(admission_apply_path(
        admission_id: @process.simple_id, id: @application.token
      ))
      expect(@application.reload.filled_form.is_filled).to be(true)
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
end

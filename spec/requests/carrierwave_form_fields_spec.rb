# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O SAPOS renderiza campo de arquivo por dois caminhos: a foto do aluno usa o
# form_ui da propria gem, e o formulario de candidatura usa
# application_helper#active_scaffold_input_carrierwave_fix -- uma copia adaptada
# do bridge do carrierwave, que chama helper interno do active_scaffold. E a
# copia que quebra quando a gem muda a assinatura do que ela chama, e nenhuma
# tela de candidato era alcancada pelo resto da suite.
#
# A classe carrierwave_controls faz parte do contrato: o script da pagina e o
# carrierwave_preview_widget.js procuram o input e o link dentro dela.
RSpec.describe "Carrierwave form fields", type: :request do
  describe "admission application form" do
    before(:each) do
      @template = FactoryBot.create(:form_template, name: "Inscrição")
      @field = FactoryBot.create(
        :form_field, form_template: @template, name: "Currículo",
        field_type: Admissions::FormField::FILE
      )
      @process = FactoryBot.create(
        :admission_process, name: "Mestrado 2026.2",
        simple_url: "mestrado-2026-2", form_template: @template,
        start_date: Date.today - 10.days,
        end_date: Date.today + 10.days,
        edit_date: Date.today + 20.days
      )
    end

    describe "GET new" do
      it "renders the form" do
        get new_admission_apply_path(admission_id: @process.simple_id)

        expect(response).to have_http_status(:ok)
      end

      it "renders the file input of the field" do
        get new_admission_apply_path(admission_id: @process.simple_id)

        expect(response.body).to include("Currículo")
        expect(response.body).to match(/<input[^>]*type="file"/)
      end
    end

    describe "GET edit with a file already sent" do
      before(:each) do
        @application = FactoryBot.create(
          :admission_application, admission_process: @process,
          filled_form: FactoryBot.create(
            :filled_form, form_template: @template, is_filled: true
          )
        )
        @application.filled_form.fields << FactoryBot.create(
          :filled_form_field, filled_form: @application.filled_form,
          form_field: @field, value: nil,
          file: Rack::Test::UploadedFile.new(
            Rails.root.join("spec", "fixtures", "user.png"), "image/png"
          )
        )
        @application.filled_form.save!
      end

      # O ramo com arquivo e outro: e o unico que monta o bloco de remocao, e o
      # que a marcacao da gem mudou de lugar.
      it "renders the form" do
        get edit_admission_apply_path(
          admission_id: @process.simple_id, id: @application.token
        )

        expect(response).to have_http_status(:ok)
      end

      it "keeps the container that the page script and the widget look into" do
        get edit_admission_apply_path(
          admission_id: @process.simple_id, id: @application.token
        )

        expect(response.body).to include("carrierwave_controls")
      end
    end
  end

  describe "student photo" do
    before(:each) do
      @role_adm = FactoryBot.create(:role_administrador)
      @admin = create_confirmed_user([@role_adm], "photo_admin@ic.uff.br")
      sign_in @admin
      @student = FactoryBot.create(:student)
    end

    it "renders the form of a student without a photo" do
      get edit_student_path(@student)

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<input[^>]*type="file"/)
    end

    context "with a photo already sent" do
      before(:each) do
        @student.photo = Rack::Test::UploadedFile.new(
          Rails.root.join("spec", "fixtures", "user.png"), "image/png"
        )
        @student.save!
      end

      it "renders the form" do
        get edit_student_path(@student)

        expect(response).to have_http_status(:ok)
      end

      it "keeps the container that the preview widget looks into" do
        get edit_student_path(@student)

        expect(response.body).to include("carrierwave_controls")
      end
    end
  end
end

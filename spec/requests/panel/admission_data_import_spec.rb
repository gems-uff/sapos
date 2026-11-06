# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Painel :: Importar edital", type: :request do
  # Multipart upload: Rack::Test::UploadedFile reads the file from disk.
  def upload(bytes, filename = "edital.zip")
    path = File.join(Dir.mktmpdir, filename)
    File.binwrite(path, bytes)
    Rack::Test::UploadedFile.new(path, "application/zip")
  end

  before(:each) do |example|
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "panel_admin@ic.uff.br"
    )
    @enable_panel = FactoryBot.create(
      :custom_variable, variable: "enable_panel", value: "yes"
    )
    sign_in(@admin) unless example.metadata[:sem_admin]
  end

  let!(:process) { FactoryBot.create(:admission_process) }
  let(:zip) { Admissions::AdmissionExportHelper.export_zip(process) }

  describe "portao do painel (enable_panel)" do
    it "redireciona para as configuracoes quando o painel esta desligado" do
      @enable_panel.update!(value: "no")

      get import_selection_processes_path

      expect(response).to redirect_to(custom_variables_path)
    end
  end

  describe "GET import" do
    it "mostra o formulario de upload" do
      get import_selection_processes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("panel.admission_data.import_title"))
      expect(response.body).to include(I18n.t("panel.admission_data.import_submit"))
    end
  end

  describe "POST import" do
    it "exige um arquivo" do
      post import_selection_processes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("panel.admission_data.import_no_file"))
    end

    it "simula sem gravar quando dry_run esta marcado" do
      archived_zip = zip
      process.destroy!

      expect do
        post import_selection_processes_path, params: { file: upload(archived_zip), dry_run: "1" }
      end.not_to change(Admissions::AdmissionProcess, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("panel.admission_data.import_report_title_dry_run"))
    end

    it "importa de verdade quando dry_run nao esta marcado" do
      archived_zip = zip
      process.destroy!

      expect do
        post import_selection_processes_path, params: { file: upload(archived_zip) }
      end.to change(Admissions::AdmissionProcess, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("panel.admission_data.import_report_title"))
    end

    it "recusa um edital que ainda existe na base" do
      archived_zip = zip

      expect do
        post import_selection_processes_path, params: { file: upload(archived_zip) }
      end.not_to change(Admissions::AdmissionProcess, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ainda existe")
    end

    it "mostra o erro quando o arquivo nao e um .zip valido" do
      post import_selection_processes_path, params: { file: upload("conteudo invalido".b) }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("não é um .zip válido")
    end
  end

  describe "autorizacao" do
    it "nega o acesso a quem nao gerencia o painel", :sem_admin do
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_desconhecido)], "sem_acesso@ic.uff.br"
      )

      get import_selection_processes_path

      # CanCan::AccessDenied nao tem mapeamento em rescue_responses, entao aparece
      # como 500 -- mesmo padrao do request spec do coletor de lixo.
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reports download gate", type: :request do
  let(:expired_message) { "Documento invalidado ou expirado" }

  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm], "reports_gate@ic.uff.br")
    sign_in @user
  end

  def carrierwave_file
    CarrierWave::Storage::ActiveRecord::ActiveRecordFile.create!(
      original_filename: "documento.pdf",
      content_type: "application/pdf",
      binary: "test content",
      medium_hash: SecureRandom.hex(16)
    )
  end

  describe "expired report with file still present" do
    it "renders the expired screen instead of downloading (by id)" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: carrierwave_file,
        expires_at: Date.yesterday
      )

      get download_report_path(report)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(expired_message)
    end

    it "renders the expired screen on the public by-identifier route" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: carrierwave_file,
        expires_at: Date.yesterday, identifier: "TEST-00001"
      )
      sign_out @user

      get "/reports/#{report.identifier}.pdf"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(expired_message)
    end
  end

  describe "invalidated report (no file)" do
    it "renders the expired/invalid screen" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: nil, expires_at: 1.year.from_now
      )

      get download_report_path(report)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(expired_message)
    end
  end

  describe "valid report with file" do
    it "redirects to the download path" do
      file = carrierwave_file
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: file, expires_at: 1.year.from_now
      )

      get download_report_path(report)

      expect(response).to redirect_to(download_path(medium_hash: file.medium_hash))
    end
  end

  # A rota de invalidacao nunca consultou cant_download?, nem antes nem agora:
  # ignore_method so e lido no view. Este exemplo prende o caminho ponta a
  # ponta, mas responde igual nas duas versoes -- quem prova a mudanca do link
  # e o grupo seguinte.
  describe "invalidating an expired report" do
    it "still purges the stored file (expiration must not block invalidation)" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: carrierwave_file,
        expires_at: Date.yesterday
      )

      put invalidate_report_path(report)

      expect(report.reload.carrierwave_file).to be_nil
      expect(report.invalidated_at).to be_present
    end
  end

  # Os dois links da listagem escondem-se por ignore_method, que o
  # active_scaffold chama em skip_action_link? -- um helper de view, nao um
  # filtro de controlador. Nenhuma requisicao a /reports/:id/download ou
  # /invalidate enxerga essa decisao, entao a unica forma de cobri-la e ler a
  # listagem renderizada. Sem este grupo, trocar o ignore_method do link de
  # invalidar por cant_download? volta a esconde-lo em todo documento vencido
  # com a suite inteira verde.
  describe "action links on the list page" do
    def list_body
      get reports_path
      expect(response).to have_http_status(:ok)
      response.body
    end

    it "hides download but keeps invalidate for an expired report with file" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: carrierwave_file,
        expires_at: Date.yesterday
      )

      body = list_body

      expect(body).not_to include("as_reports-download-#{report.id}-link")
      expect(body).to include("as_reports-invalidate-#{report.id}-link")
    end

    it "keeps both links for a valid report with file" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: carrierwave_file,
        expires_at: 1.year.from_now
      )

      body = list_body

      expect(body).to include("as_reports-download-#{report.id}-link")
      expect(body).to include("as_reports-invalidate-#{report.id}-link")
    end

    # Sem arquivo nao ha o que baixar nem o que apagar, e invalidate! estoura
    # em carrierwave_file.delete se chegar la.
    it "hides both links once the file is gone" do
      report = FactoryBot.create(
        :report, user: @user, carrierwave_file: nil, expires_at: 1.year.from_now
      )

      body = list_body

      expect(body).not_to include("as_reports-download-#{report.id}-link")
      expect(body).not_to include("as_reports-invalidate-#{report.id}-link")
    end
  end
end

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
end

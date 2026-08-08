# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "NotificationsController", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm])
    sign_in @user

    @query = FactoryBot.create(
      :query, name: "students", sql: "select * from students"
    )
    @notification = FactoryBot.create(
      :notification, query: @query, title: "Prazos",
      to_template: "sapos-teste@ic.uff.br", subject_template: "Prazo",
      body_template: "Prezado aluno"
    )
  end

  describe "GET simulate with a date that cannot be read" do
    # Data mal digitada na tela de simulação é erro de quem preenche, não
    # defeito: deve virar aviso na própria tela, não página de erro.
    it "shows the simulation with a warning instead of failing" do
      get simulate_notification_path(@notification),
        params: { query_params: { data_consulta: "31/31/2026" } }

      expect(response).to have_http_status(:ok)
      expect(flash[:alert]).to eq I18n.t(
        "activerecord.errors.models.notification.invalid_query_date",
        date: "31/31/2026"
      )
    end

    it "still reads a date that carries a time and a time zone" do
      get simulate_notification_path(@notification),
        params: { query_params: { data_consulta: "2026-07-01 00:00:00 -0300" } }

      expect(response).to have_http_status(:ok)
      expect(flash[:alert]).to be_nil
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Busca por data relativa do active_scaffold ("nos ultimos N dias"): a unidade
# vem do formulario e so pode ser uma das unidades de data ou hora
# (config/initializers/active_scaffold_date_trend_unit.rb).
RSpec.describe "Busca por data relativa", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_trend@ic.uff.br", "Adm")
    FactoryBot.create(:advisement_authorization, start_date: 3.days.ago.to_date,
      professor: FactoryBot.create(:professor, name: "Professora Recente"))
    FactoryBot.create(:advisement_authorization, start_date: 3.years.ago.to_date,
      professor: FactoryBot.create(:professor, name: "Professora Antiga"))
  end

  def busca(unidade)
    get advisement_authorizations_path, params: {
      search: { start_date: { opt: "PAST", number: "10", unit: unidade } }
    }
    ["Professora Recente", "Professora Antiga"].select { |nome| response.body.include?(nome) }
  end

  it "filtra pelos ultimos dias" do
    expect(busca("DAYS")).to eq(["Professora Recente"])
    expect(response).to have_http_status(:ok)
  end

  it "filtra pelos ultimos anos" do
    expect(busca("YEARS")).to eq(["Professora Recente", "Professora Antiga"])
  end

  it "ignora unidade que nao e de data nem de hora" do
    expect(busca("raise")).to eq(["Professora Recente", "Professora Antiga"])
    expect(response).to have_http_status(:ok)
  end
end

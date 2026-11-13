# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A busca do record_select de linhas de pesquisa (campos de linha nos
# formularios de linha de pesquisa do curso e do professor) deveria oferecer so
# linha disponivel de area disponivel (#408). Nenhum exemplo abria a busca (#720).
RSpec.describe "Busca de linhas de pesquisa pelo record_select", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_linhas@ic.uff.br", "Adm")
    area = FactoryBot.create(:research_area)
    area_fechada = FactoryBot.create(:research_area, available: false)
    FactoryBot.create(:research_line, name: "Linha Aberta Um", research_area: area)
    FactoryBot.create(:research_line, name: "Linha Aberta Dois", research_area: area)
    FactoryBot.create(:research_line, name: "Linha Fechada", research_area: area, available: false)
    FactoryBot.create(:research_line, name: "Linha De Area Fechada", research_area: area_fechada)
  end

  def busca
    get "/research_lines/browse", params: { search: "linha" }, xhr: true,
      headers: { "HTTP_REFERER" => "http://www.example.com/course_research_lines/new" }
  end

  # Controle: o cenario monta as duas linhas que a busca deveria oferecer.
  it "o cenario tem duas linhas disponiveis de area disponivel" do
    disponiveis = ResearchLine.joins(:research_area)
      .where(available: true, research_areas: { available: true }).pluck(:name)

    expect(disponiveis).to contain_exactly("Linha Aberta Um", "Linha Aberta Dois")
  end

  # A condicao vai como subconsulta escalar crua no WHERE: em SQLite ela nao
  # filtra nada; em MariaDB, com duas linhas disponiveis, da "Subquery returns
  # more than 1 row" e a busca responde 500.
  it "oferece so as linhas disponiveis de area disponivel", pending: "issue #722" do
    busca

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Linha Aberta Um", "Linha Aberta Dois")
    expect(response.body).not_to include("Linha Fechada")
    expect(response.body).not_to include("Linha De Area Fechada")
  end
end

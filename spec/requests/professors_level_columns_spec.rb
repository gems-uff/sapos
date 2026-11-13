# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A lista de professores ganha uma coluna de pontos por nivel marcado com
# show_advisements_points_in_list. As colunas sao montadas no bloco
# active_scaffold do controller, que o active_scaffold avalia uma vez por
# processo, no primeiro acesso a configuracao: nivel marcado depois disso so
# aparece quando o processo reinicia (#720).
RSpec.describe "Colunas de pontos por nivel na lista de professores", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_niveis@ic.uff.br", "Adm")
    FactoryBot.create(:professor, name: "Professora Teste")
    get professors_path
  end

  def cabecalhos
    Nokogiri::HTML(response.body).css("tr th").map { |th| th.text.strip }
  end

  # Controle: a lista abre de novo depois de o nivel ser marcado.
  it "continua abrindo a lista depois de marcar um nivel" do
    FactoryBot.create(:level, show_advisements_points_in_list: true,
      short_name_showed_in_list_header: "NivelNovo")

    get professors_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Professora Teste")
  end

  it "mostra a coluna do nivel marcado depois de a lista ter sido aberta", pending: "issue #723" do
    FactoryBot.create(:level, show_advisements_points_in_list: true,
      short_name_showed_in_list_header: "NivelNovo")

    get professors_path

    expect(cabecalhos).to include("NivelNovo")
  end
end

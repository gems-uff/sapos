# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A exibicao da candidatura embute quatro listas do active_scaffold -- cartas,
# resultados de fase, avaliacoes e ranking -- pelos *_show_column de
# Admissions::AdmissionApplicationsHelper, que chamam `render active_scaffold:`
# com parent_scaffold e association. E API interna do active_scaffold que
# nenhum exemplo exercitava (#720); um minor que mudasse o render embutido
# derrubaria a tela da candidatura sem vermelho.
RSpec.describe "Exibicao da candidatura com as listas embutidas", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_candidatura@ic.uff.br", "Adm"
    )
    @candidatura = FactoryBot.create(:admission_application, :in_process_with_letters)
    FactoryBot.create(:letter_request, admission_application: @candidatura, name: "Recomendante Um")
    FactoryBot.create(:admission_phase_result, admission_application: @candidatura)
    FactoryBot.create(:admission_phase_evaluation, admission_application: @candidatura)
    FactoryBot.create(:admission_ranking_result, admission_application: @candidatura)

    get admission_application_path(@candidatura)
    @pagina = response
  end

  # O render embutido sai com embedded[loading]=true: a tela traz so o
  # marcador, com a URL que o navegador pede em seguida para preencher a lista.
  def recarga(caminho)
    html = Nokogiri::HTML(@pagina.body)
    marcador = html.css(".active-scaffold-component[data-refresh]")
      .find { |div| div["data-refresh"].start_with?("#{caminho}?") }
    marcador && CGI.unescapeHTML(marcador["data-refresh"])
  end

  it "abre a tela" do
    expect(@pagina).to have_http_status(:ok)
  end

  {
    "cartas" => ["/letter_requests", "letter_requests"],
    "resultados de fase" => ["/admission_phase_results", "results"],
    "avaliacoes" => ["/admission_phase_evaluations", "evaluations"],
    "ranking" => ["/admission_ranking_results", "rankings"],
  }.each do |lista, (caminho, associacao)|
    it "embute a lista de #{lista}, presa a candidatura pela associacao" do
      url = recarga(caminho)

      expect(url).to be_present
      parametros = Rack::Utils.parse_nested_query(URI(url).query)
      expect(parametros).to include(
        "admission_application_id" => @candidatura.id.to_s,
        "association" => associacao,
        "parent_scaffold" => "admissions/admission_applications"
      )
    end

    it "preenche a lista de #{lista} quando o navegador a pede" do
      get recarga(caminho), xhr: true

      expect(response).to have_http_status(:ok)
    end
  end

  it "traz a carta da candidatura na lista de cartas" do
    get recarga("/letter_requests"), xhr: true

    expect(response.body).to include("Recomendante Um")
  end
end

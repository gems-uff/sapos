# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Lista e detalhe de versoes (#720). A lista so via versoes de objeto vivo com
# rota propria; o objeto apagado, o modelo sem `<item_type>_path` (todo modelo
# de admissions cai no rescue) e o detalhe com a versao anterior nunca rodavam.
RSpec.describe "Versoes: lista e detalhe", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_versoes_colunas@ic.uff.br", "Adm"
    )
  end

  def linha_da_lista(version)
    Nokogiri::HTML(response.body).css("tr[id$='-#{version.id}-row']").first
  end

  def objeto_atual(version)
    linha_da_lista(version).css("td.current_object-column").text.squish
  end

  it "a lista marca o objeto apagado" do
    pais = FactoryBot.create(:country, name: "Pais Apagado")
    pais.destroy!
    versao = Version.where(item_type: "Country", item_id: pais.id, event: "destroy").last

    get versions_path

    expect(response).to have_http_status(:ok)
    expect(objeto_atual(versao)).to eq("Objeto Deletado")
  end

  it "a lista troca o link por texto quando o modelo nao tem rota" do
    maquina = FactoryBot.create(:ranking_machine, name: "Maquina Versionada")
    versao = Version.where(item_type: "Admissions::RankingMachine", item_id: maquina.id).last

    get versions_path

    expect(response).to have_http_status(:ok)
    expect(objeto_atual(versao)).to eq("Objeto de Relacionamento")
  end

  # Controle: objeto vivo com rota vira link para ele.
  it "a lista liga o objeto vivo com rota" do
    pais = FactoryBot.create(:country, name: "Pais Vivo")
    versao = Version.where(item_type: "Country", item_id: pais.id).last

    get versions_path

    link = linha_da_lista(versao).css("td.current_object-column a").first
    expect(link.text).to eq("Pais Vivo")
    expect(link["href"]).to eq(country_path(pais))
  end

  describe "detalhe" do
    def versao_anterior
      Nokogiri::HTML(response.body).css("dd.old_version-view").first
    end

    # A versao de update guarda o objeto antes da mudanca, em YAML; o detalhe
    # lista uma propriedade por linha, sem datas (_at) e escapando o conteudo.
    it "lista as propriedades do objeto anterior" do
      pais = FactoryBot.create(:country, name: "Pais <b>Antigo</b>")
      pais.update!(name: "Pais Novo")
      versao = Version.where(item_type: "Country", item_id: pais.id, event: "update").last

      get version_path(versao)

      expect(response).to have_http_status(:ok)
      linhas = versao_anterior.inner_html.split("<br>").map(&:strip).reject(&:empty?)
      expect(linhas).to include("name: Pais &lt;b&gt;Antigo&lt;/b&gt;", "id: #{pais.id}")
      expect(linhas.join).not_to include("created_at", "updated_at")
      expect(linhas).not_to include("---")
    end

    it "fica vazio na versao de criacao" do
      pais = FactoryBot.create(:country, name: "Pais Criado")
      versao = Version.where(item_type: "Country", item_id: pais.id, event: "create").last

      get version_path(versao)

      expect(response).to have_http_status(:ok)
      expect(versao_anterior.text.strip).to eq("")
    end
  end
end

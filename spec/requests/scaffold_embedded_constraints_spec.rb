# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A lista embutida do active_scaffold leva as restrições na URL
# (embedded[constraints]), e a gem as aplica sem conferir de onde vieram:
# filtram a lista por qualquer coluna do banco e, na criação, gravam por setter
# qualquer atributo do registro novo, fora das colunas do formulário. O SAPOS
# não embute lista com restrição; aqui se cobra que nenhuma da requisição valha
# (config/initializers/active_scaffold_embedded_constraints.rb).
RSpec.describe "Restricoes de lista embutida vindas da URL", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include AbilityDataset

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
  end
  after(:each) { travel_back }

  def remoto
    { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
  end

  # Um controller que redefinisse o método passaria na frente do remendo.
  it "nao le restricao da requisicao em scaffold nenhum" do
    Rails.application.eager_load!
    scaffolds = ApplicationController.descendants.select do |klass|
      klass.respond_to?(:active_scaffold_config) && klass.active_scaffold_config
    rescue StandardError
      false
    end
    expect(scaffolds.size).to be > 50

    lidas = scaffolds.filter_map do |klass|
      controller = klass.new
      controller.params = ActionController::Parameters.new(embedded: { constraints: { created_at: "2000-01-01" } })
      restricoes = controller.send(:active_scaffold_constraints)
      "#{klass.name}: #{restricoes}" unless restricoes == {}
    end
    expect(lidas).to eq([])
  end

  describe "na criacao, pelo administrador" do
    before(:each) { sign_in @users[:administrador] }

    def pais(nome, extra = {})
      post "/countries", xhr: true, env: remoto, params: { record: { name: nome, nationality: "x" } }.merge(extra)
      Country.find_by(name: nome)
    end

    it "nao grava atributo fora do formulario" do
      criado = pais("PaisRestrito", embedded: { constraints: { created_at: "2000-01-01 00:00:00" } })

      expect(criado).not_to be_nil
      expect(criado.created_at.year).not_to eq(2000)
    end

    # Controle: o mesmo atributo pelo formulário já era ignorado.
    it "controle: atributo fora do formulario, mandado em record[], e ignorado" do
      post "/countries", xhr: true, env: remoto,
        params: { record: { name: "PaisControle", nationality: "x", created_at: "2000-01-01 00:00:00" } }

      criado = Country.find_by(name: "PaisControle")
      expect(criado).not_to be_nil
      expect(criado.created_at.year).not_to eq(2000)
    end
  end

  # O professor cria artigo, e o artigo tem a coleção de versões do PaperTrail
  # entre as colunas do scaffold: a restrição puxava para o artigo novo a
  # versão de qualquer outro registro, que sumia do histórico dele.
  describe "na criacao de artigo, pelo professor" do
    before(:each) do
      @professor = @users[:professor]
      sign_in @professor
    end

    def artigo(extra = {})
      post "/papers", xhr: true, env: remoto, params: {
        record: {
          period: CustomVariable.quadrennial_period, owner: @professor.professor.id.to_s,
          reference: "REFERENCIA-RESTRITA", order: "3", kind: "Periódico", doi_issn_event: "1",
          reason_international_list: "1", reason_justify: "x",
        },
      }.merge(extra)
      Paper.find_by(reference: "REFERENCIA-RESTRITA")
    end

    it "nao puxa para o artigo a versao de outro registro" do
      versao = PaperTrail::Version.where.not(item_type: "Paper").first
      antes = [versao.item_type, versao.item_id]

      criado = artigo(embedded: { constraints: { versions: versao.id.to_s } })

      expect(criado).not_to be_nil
      versao.reload
      expect([versao.item_type, versao.item_id]).to eq(antes)
    end

    it "nao grava a data de criacao" do
      criado = artigo(embedded: { constraints: { created_at: "2000-01-01 00:00:00" } })

      expect(criado).not_to be_nil
      expect(criado.created_at.year).not_to eq(2000)
    end

    # Controle: sem a restrição, o mesmo pedido cria o artigo do professor.
    it "controle: cria o artigo" do
      criado = artigo

      expect(criado).not_to be_nil
      expect(criado.owner_id).to eq(@professor.professor.id)
    end
  end

  describe "na lista" do
    before(:each) do
      sign_in @users[:administrador]
      FactoryBot.create(:country, name: "PaisAlfa")
      FactoryBot.create(:country, name: "PaisBeta")
    end

    def lista(params = {})
      get "/countries", params: params, env: remoto
      expect(response).to have_http_status(:ok)
      %w[PaisAlfa PaisBeta].select { |nome| response.body.include?(nome) }
    end

    it "nao filtra pela restricao" do
      expect(lista(embedded: { constraints: { name: "PaisAlfa" } })).to eq(%w[PaisAlfa PaisBeta])
    end

    # A gem recusava com erro a restrição que não fosse coluna; ignorada, a
    # lista abre.
    it "abre com restricao que nao e coluna" do
      expect(lista(embedded: { constraints: { inexistente: "1" } })).to eq(%w[PaisAlfa PaisBeta])
    end

    it "controle: sem restricao, a lista traz os dois" do
      expect(lista).to eq(%w[PaisAlfa PaisBeta])
    end
  end
end

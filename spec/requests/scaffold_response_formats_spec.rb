# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O active_scaffold responde a listagem e a ficha de todo scaffold também em
# JSON e XML, com a coluna crua e, para cada coluna de associação, o registro
# associado com todos os atributos. Nada disso passa pelos helpers nem pelas
# guardas de campo da tela: é um segundo caminho de leitura, que nenhuma tela
# do SAPOS usa. Aqui se cobra que ele não exista.
RSpec.describe "Formatos de resposta dos scaffolds", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include AbilityDataset
  include RouteProbe

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
    @administrador = vestir_perfil(perfil("administrador"))
  end
  after(:each) { travel_back }

  # Entra de novo a cada pedido: a exceção de um pedido recusado derruba a
  # sessão do teste, e o seguinte sairia como 401 do Devise.
  def pedir(caminho, **opcoes)
    sign_in @administrador
    get caminho, env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }, **opcoes
    response.status
  rescue ActionController::UnknownFormat
    :formato_recusado
  rescue StandardError => e
    "erro #{e.class}"
  end

  # O administrador pode tudo: se o formato respondesse, responderia a ele. Só
  # entra na conta o endereço que abre em HTML para ele, que é o controle de
  # cada linha: ali a recusa só pode vir do formato.
  it "nao entrega a listagem nem a ficha em JSON ou XML, em scaffold nenhum" do
    entregues = []
    conferidos = 0
    scaffolds = RouteProbe.routes.select do |rota|
      rota.verb == "GET" && %w[index show].include?(rota.action) && RouteProbe.model_for(rota.controller)
    end

    scaffolds.each do |rota|
      partes = rota.journey.required_parts
      next unless partes.empty? || partes == [:id]

      registro = RouteProbe.model_for(rota.controller).unscoped.first
      next if partes == [:id] && registro.nil?

      caminho = route_path(rota, id: registro&.id)
      next unless pedir(caminho) == 200

      conferidos += 1
      %w[json xml].each do |formato|
        desfecho = pedir("#{caminho}.#{formato}")
        entregues << "#{rota} .#{formato}: #{desfecho}" unless desfecho == :formato_recusado
      end
    end

    expect(conferidos).to be > 150
    expect(entregues).to be_empty, "scaffold respondeu fora de HTML e JS:\n#{entregues.join("\n")}"
  end

  # Controle: os mesmos endereços seguem respondendo em HTML e, por XHR, em JS.
  it "segue entregando a listagem em HTML e em JS" do
    expect(pedir("/students")).to eq(200)
    expect(pedir("/students", xhr: true)).to eq(200)
    expect(pedir("/students.js", xhr: true)).to eq(200)
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Guarda estrutural das rotas — issue #742.
#
# O visitante e um usuário logado sem papel nenhum batem em toda rota da
# aplicação, com o verbo dela. Quem não tem permissão para nada só pode
# receber recusa; o que ele consegue abrir tem de estar em
# RouteProbe::ROTAS_ABERTAS, com o motivo ao lado. Assim um controller novo sem
# autorização, ou um skip_authorization_check mais largo do que devia, quebra a
# suíte em vez de passar calado — o check_authorization do ApplicationController
# não pega quem o desliga, e é exatamente isso que o processo seletivo e o
# download fazem.
#
# O baseline spec/goldens/rotas_sem_permissao.txt registra o desfecho de cada
# rota, para que mudança em rota recusada também apareça.
RSpec.describe "Rotas para quem não tem permissão", type: :request do
  include GoldenMaster
  include AbilityDataset
  include RouteProbe

  # 401 é o Devise recusando o visitante numa rota de formato não HTML (pdf).
  RECUSAS = ["negado", "negado (active_scaffold)", "ação inexistente", "302 /users/sign_in", "401"].freeze

  before(:each) do
    travel_to GoldenMaster::FROZEN_AT
    build_ability_dataset
    arquivo = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.create!(
      original_filename: "documento.pdf", content_type: "application/pdf",
      binary: "conteudo", medium_hash: "a" * 32
    )
    @relatorio = label(
      FactoryBot.create(:report, user: @users[:administrador], carrierwave_file: arquivo, file_name: "documento.pdf"),
      "relatorio"
    )
    @relatorio_sem_arquivo = label(
      FactoryBot.create(:report, user: @users[:administrador], file_name: "vencido.pdf"),
      "relatorio_sem_arquivo"
    )
    @extra = {
      admission_id: @labels.key("processo").id,
      medium_hash: arquivo.medium_hash,
      identifier: @relatorio.identifier,
    }
  end
  after(:each) { travel_back }

  def id_for(route)
    model = RouteProbe.model_for(route.controller)
    return 0 if model.nil?

    labeled = @labels.keys.find { |record| record.instance_of?(model) && record.persisted? }
    (labeled || model.first)&.id || 0
  end

  def percorrer(users)
    RouteProbe.routes.map do |route|
      path = route_path(route, id: id_for(route), extra: @extra)
      outcomes = users.to_h do |name, user|
        sign_out :user
        sign_in user if user
        [name, probe(route, path)]
      end
      [route, outcomes]
    end
  end

  it "recusa tudo fora das rotas abertas, e mantém o baseline" do
    resultados = percorrer("visitante" => nil, "sem papel" => @users[:desconhecido])

    linhas = resultados.map do |route, outcomes|
      "#{route} | #{outcomes.map { |name, outcome| "#{name}: #{outcome}" }.join(' | ')}"
    end
    abertas_sem_motivo = resultados.filter_map do |route, outcomes|
      passou = outcomes.reject { |_name, outcome| RECUSAS.include?(outcome) || outcome.start_with?("não encontrado") }
      "#{route} => #{passou}" if passou.any? && !RouteProbe.aberta?(route)
    end

    expect(abertas_sem_motivo).to be_empty,
      "rotas que quem não tem permissão abre, sem estar em RouteProbe::ROTAS_ABERTAS:\n#{abertas_sem_motivo.join("\n")}"
    expect_matches_golden("rotas_sem_permissao", "#{linhas.join("\n")}\n", format: :text)
  end

  # O set_report e o check_downloadable rodam antes do authorize_resource. O
  # relatório com arquivo, que é o que tem conteúdo, é recusado; o sem arquivo
  # responde a qualquer logado com a página de "invalidado ou expirado", que é o
  # que a validação pública pelo identificador já mostra.
  it "recusa o download do relatório de outro usuário" do
    sign_in @users[:desconhecido]
    route = RouteProbe.routes.find { |r| r.controller == "reports" && r.action == "download" }

    expect(probe(route, route_path(route, id: @relatorio.id))).to eq("negado")
    sign_in @users[:desconhecido]
    expect(probe(route, route_path(route, id: @relatorio_sem_arquivo.id))).to eq("200")
    expect(response.body).to include("Documento invalidado ou expirado")
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Declarações e notificações recebem os valores dos parâmetros da consulta em
# params[:query_params]. Antes, um permit! deixava passar qualquer chave; agora
# só passam as que a consulta declara, mais a que o próprio controller lê fora
# da consulta: matricula_aluno na declaração (a autorização de
# generate_assertion) e data_consulta na notificação (a derivação que o
# formulário de simulação envia e de onde as demais são calculadas).
#
# A diferença não aparece na resposta, porque Query#map_params já ignorava
# chave desconhecida. O que se mede é o hash que chega ao modelo, capturado
# no ponto em que o controller o entrega.
RSpec.describe "Parâmetros de consulta: só as chaves declaradas passam", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    sign_in create_confirmed_user([@role_adm], "query_params_admin@ic.uff.br")
    # A consulta DEVOLVE uma linha de propósito: as views de simulação têm
    # blocos que só renderizam com resultado (o botão de PDF da declaração, o
    # link "Notificar agora"), e foi num deles que a homologação acusou 500 --
    # params[:query_params] cru, não permitido, convertido em hash na view. Com
    # consulta vazia o spec passava e o defeito seguia.
    @query = FactoryBot.create(:query, name: "alunos", sql: "select 'linha' as coluna")
    FactoryBot.create(:query_param, query: @query, name: "_a", value_type: "String", default_value: "")
  end

  describe "declaração (simulate)" do
    before(:each) do
      @assertion = Assertion.create!(
        name: "Declaração", query: @query, template_type: "Liquid",
        assertion_template: "ok", student_can_generate: false
      )
    end

    it "entrega à consulta a chave declarada e matricula_aluno, e descarta a não declarada" do
      # Query#query_results chama map_params de novo, já com o hash mapeado;
      # o que interessa é a PRIMEIRA chamada, a que recebe o que o controller
      # entregou.
      captured = nil
      allow_any_instance_of(Query).to receive(:map_params).and_wrap_original do |m, *args|
        captured ||= args.first
        m.call(*args)
      end

      get simulate_assertion_path(@assertion), params: {
        query_params: { _a: "x", matricula_aluno: "M01", nao_declarada: "y" }
      }

      expect(response).to have_http_status(:ok)
      expect(captured.keys.map(&:to_s).sort).to eq(%w[_a matricula_aluno])
    end

    it "não quebra quando query_params não vem" do
      get simulate_assertion_path(@assertion)
      expect(response).to have_http_status(:ok)
    end

    it "renderiza com resultado e leva ao botão de PDF só as chaves permitidas" do
      get simulate_assertion_path(@assertion), params: {
        query_params: { _a: "x", nao_declarada: "y" }
      }

      expect(response).to have_http_status(:ok)
      botao = Nokogiri::HTML(response.body).at_css("[data-query-params]")
      expect(botao).not_to be_nil
      expect(JSON.parse(botao["data-query-params"])).to eq("_a" => "x")
    end
  end

  describe "notificação (simulate)" do
    before(:each) do
      @notification = FactoryBot.create(
        :notification, query: @query, title: "Prazos",
        to_template: "sapos-teste@ic.uff.br", subject_template: "Prazo",
        body_template: "Prezado aluno"
      )
    end

    it "entrega à notificação a chave declarada e data_consulta, e descarta a não declarada" do
      captured = nil
      allow_any_instance_of(Notification).to receive(:execute).and_wrap_original do |m, *args, **kwargs|
        captured = kwargs[:override_params]
        m.call(*args, **kwargs)
      end

      get simulate_notification_path(@notification), params: {
        query_params: { _a: "x", data_consulta: "15/06/2021", nao_declarada: "y" }
      }

      expect(response).to have_http_status(:ok)
      keys = captured.keys.map(&:to_s)
      expect(keys).to include("_a", "data_consulta")
      expect(keys).not_to include("nao_declarada")
      # As derivações continuam sendo calculadas a partir de data_consulta.
      expect(keys).to include("ano_semestre_atual", "numero_semestre_atual")
    end

    it "renderiza com resultado e data inválida, mostrando a data digitada e o link de notificar" do
      get simulate_notification_path(@notification), params: {
        query_params: { _a: "x", data_consulta: "31/31/2026", nao_declarada: "y" }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("31/31/2026")
      link = Nokogiri::HTML(response.body).at_css("a.execute_now")
      expect(link).not_to be_nil
      expect(link["href"]).to include("query_params%5B_a%5D=x")
      expect(link["href"]).not_to include("nao_declarada")
    end
  end
end

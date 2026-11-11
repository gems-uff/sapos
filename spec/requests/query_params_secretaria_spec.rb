# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A secretaria usa as consultas, mas não as escreve: não cria, não altera e
# não apaga consulta, declaração nem notificação. O parâmetro da consulta é
# parte dela — muda o que a consulta devolve, e com ela a declaração e a
# notificação que a usam — e segue a mesma regra. Ver, executar e simular
# continuam abertos; a recusa se julga pelo banco, porque o cancancan a
# entrega como 500 (ver cancancan_denials_spec.rb).
RSpec.describe "Parâmetros de consulta pela secretaria", type: :request do
  include_context "consulta somente-leitura na conexao do teste"

  before(:each) do
    FactoryBot.create(:enrollment, enrollment_number: "M-PARAM-1")
    @query = Query.new(
      name: "consulta_com_parametro",
      sql: "select enrollment_number as matricula from enrollments where enrollment_number = :matricula_aluno"
    )
    @param = @query.params.build(name: "matricula_aluno", value_type: "String", default_value: "padrao")
    @query.save!
    @assertion = Assertion.create!(
      name: "Declaracao com parametro", query: @query,
      template_type: "Liquid", assertion_template: "Matricula: {{ matricula }}"
    )
    sign_in create_confirmed_user([FactoryBot.create(:role_secretaria)], "sec.param@ic.uff.br", "Secretaria")
  end

  let(:valores) { { query_params: { matricula_aluno: "M-PARAM-1" } } }

  describe "o que a secretaria faz com a consulta" do
    it "vê a consulta com os parâmetros" do
      get query_path(@query)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("matricula_aluno")
    end

    it "executa a consulta" do
      get execute_query_path(@query), params: valores

      expect(response).to have_http_status(:ok)
    end

    it "simula e gera a declaração que usa a consulta" do
      get simulate_assertion_path(@assertion), params: valores
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("matricula_aluno")

      get assertion_pdf_assertion_path(@assertion, format: :pdf), params: valores
      expect(response.media_type).to eq("application/pdf")
    end
  end

  describe "o que ela não faz com o parâmetro" do
    # Fora de IP local a recusa do cancancan sobe como exceção (ver
    # RouteProbe::REMOTE_ADDR): é ela que separa "o papel não pode" de "o
    # pedido não gravou por outro motivo".
    def desfecho
      yield
      :passou
    rescue CanCan::AccessDenied
      :negado
    end

    def remoto
      { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
    end

    def alterar
      desfecho { patch query_param_path(@param), params: { record: { default_value: "alterado" } }, env: remoto }
    end

    def apagar
      desfecho { delete query_param_path(@param), env: remoto }
    end

    def criar
      desfecho do
        post query_params_path, env: remoto,
          params: { record: { name: "novo", value_type: "String", query: @query.id } }
      end
    end

    it "não altera o valor padrão" do
      expect(alterar).to eq(:negado)
      expect(@param.reload.default_value).to eq("padrao")
    end

    it "não apaga o parâmetro" do
      expect(apagar).to eq(:negado)
      expect(QueryParam.exists?(@param.id)).to be(true)
    end

    it "não cria parâmetro" do
      expect { expect(criar).to eq(:negado) }.not_to change(QueryParam, :count)
    end

    # Controle: os mesmos pedidos, feitos pela coordenação, passam pela
    # autorização; os que a tela sabe gravar, gravam.
    context "os mesmos pedidos, pela coordenação" do
      before(:each) do
        sign_out :user
        sign_in create_confirmed_user([FactoryBot.create(:role_coordenacao)], "coord.param@ic.uff.br", "Coordenacao")
      end

      it "altera o valor padrão" do
        expect(alterar).to eq(:passou)
        expect(@param.reload.default_value).to eq("alterado")
      end

      it "apaga o parâmetro" do
        expect(apagar).to eq(:passou)
        expect(QueryParam.exists?(@param.id)).to be(false)
      end

      it "passa pela autorização ao criar" do
        expect(criar).to eq(:passou)
      end
    end
  end
end

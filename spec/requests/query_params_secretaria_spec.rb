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
    def tenta
      yield
    rescue CanCan::AccessDenied
      nil
    end

    it "não altera o valor padrão" do
      tenta { patch query_param_path(@param), params: { record: { default_value: "alterado" } } }

      expect(@param.reload.default_value).to eq("padrao")
    end

    it "não apaga o parâmetro" do
      tenta { delete query_param_path(@param) }

      expect(QueryParam.exists?(@param.id)).to be(true)
    end

    it "não cria parâmetro" do
      expect {
        tenta { post query_params_path, params: { record: { name: "novo", value_type: "String", query: @query.id } } }
      }.not_to change(QueryParam, :count)
    end
  end
end

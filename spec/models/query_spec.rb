# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Query, type: :model do
  it { should have_many(:notifications).inverse_of(:query) }
  it { should have_many(:params).class_name("QueryParam").dependent(:destroy).validate(false) }

  let(:query) do
    Query.new(
      name: "query",
      sql: "SELECT students.name as name FROM students",
    )
  end
  subject { query }
  context "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:sql) }

    context "sql has an undefined parameter" do
      it "show an undefined parameter error on sql" do
        query.sql = "SELECT students.name as name FROM students\r\nWHERE students.created_at < :data_consulta"
        query.validate
        expect(query.errors[:sql]).to include I18n.translate("activerecord.errors.models.query.sql_has_an_undefined_parameter", parametro: "data_consulta")
      end
    end
    context "sql has an syntax error" do
      it "show an message about sql execution causing an error on sql" do
        query.sql = "aSELECT students.name as name FROM students"
        inicio_da_mensagem = I18n.translate("activerecord.errors.models.query.sql_execution_generated_an_error", erro: "mensagem_de_erro").split("mensagem_de_erro")[0]
        fim_da_mensagem = I18n.translate("activerecord.errors.models.query.sql_execution_generated_an_error", erro: "mensagem_de_erro").split("mensagem_de_erro")[1]
        query.validate
        expect((query.errors[:sql][0].start_with?(inicio_da_mensagem)) && (query.errors[:sql][0].end_with?(fim_da_mensagem))).to be true
      end
    end
    context "query is valid" do
      it "have no errors on a valid query execution" do
        query.name = "nome"
        query.description = "descricao"
        query.sql = "SELECT students.name as name FROM students\r\nWHERE students.created_at < :data_consulta"
        parameter = query.params.new
        parameter.name = "data_consulta"
        parameter.value_type = "Date"
        expect(query).to be_valid
      end
    end
  end
end

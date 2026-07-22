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

  context "Methods" do
    describe ".run_read_only_query" do
      let(:sql) { "SELECT students.name AS name FROM students" }

      context "when the connection adapter is SQLite" do
        it "returns the columns and rows reported by the connection" do
          expect(Query.run_read_only_query(sql)).to eq(columns: ["name"], rows: [])
        end
      end

      context "when the connection adapter is Mysql2" do
        # A suite roda em SQLite, entao este ramo nunca e exercitado de fato.
        # Os stubs existem para fixar as APIs de que ele depende --
        # configs_for, configuration_hash e Mysql2::Client -- que mudam entre
        # versoes do Rails e cuja quebra so apareceria em producao.
        let(:connection) { double("connection", adapter_name: "Mysql2") }
        let(:results) do
          double("Mysql2::Result", fields: ["name"], entries: [{ "name" => "Fulano" }])
        end
        let(:client) { double("Mysql2::Client instance", query: results, close: nil) }
        let(:client_class) { double("Mysql2::Client", new: client) }

        before do
          allow(ApplicationRecord).to receive(:connection).and_return(connection)
          allow(ApplicationRecord).to receive(:configurations).and_return(configurations)
          stub_const("Mysql2::Client", client_class)
        end

        context "when a read only configuration exists for the environment" do
          let(:configurations) do
            ActiveRecord::DatabaseConfigurations.new(
              "test" => { "adapter" => "mysql2", "database" => "main" },
              "test_read_only" => { "adapter" => "mysql2", "database" => "read_only" }
            )
          end

          it "connects using the read only configuration" do
            Query.run_read_only_query(sql)
            expect(client_class).to have_received(:new).with(hash_including(database: "read_only"))
          end
        end

        context "when there is no read only configuration for the environment" do
          let(:configurations) do
            ActiveRecord::DatabaseConfigurations.new(
              "test" => { "adapter" => "mysql2", "database" => "main" }
            )
          end

          it "falls back to the configuration of the environment" do
            Query.run_read_only_query(sql)
            expect(client_class).to have_received(:new).with(hash_including(database: "main"))
          end

          it "returns the columns and rows extracted from the result" do
            expect(Query.run_read_only_query(sql)).to eq(columns: ["name"], rows: [["Fulano"]])
          end

          it "closes the client" do
            Query.run_read_only_query(sql)
            expect(client).to have_received(:close)
          end
        end
      end
    end
  end
end

# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe Query do

  let(:query) {Query.new}
  subject { query }
  context "creating or updating" do

    context "name is blank" do
      it "show an blank error on name" do
	query.name = nil     
        expect(query).to have_error(:blank).on :name
      end
    end
    context "sql is blank" do
      it "show an blank error on sql" do
        query.sql = ""      
        expect(query).to have_error(:blank).on :sql
      end
    end
    context "sql has an undefined parameter" do
      it "show an undefined parameter error on sql" do      	    
        query.sql = "SELECT students.name as name FROM students\r\nWHERE students.created_at < :data_consulta"
        query.validate
	expect(query.errors[:sql]).to include I18n.translate("activerecord.errors.models.query.sql_has_an_undefined_parameter", :parametro=>"data_consulta")
      end
    end
    context "sql has an syntax error" do
      it "show an message about sql execution causing an error on sql" do      	    
        query.sql = "aSELECT students.name as name FROM students"
	inicio_da_mensagem = I18n.translate("activerecord.errors.models.query.sql_execution_generated_an_error", :erro=>"mensagem_de_erro").split("mensagem_de_erro")[0]
	fim_da_mensagem = I18n.translate("activerecord.errors.models.query.sql_execution_generated_an_error", :erro=>"mensagem_de_erro").split("mensagem_de_erro")[1]
        query.validate
	expect( (query.errors[:sql][0].start_with?(inicio_da_mensagem)) && (query.errors[:sql][0].end_with?(fim_da_mensagem))  ).to be true
      end
    end
    context "query is valid" do
      it "have no errors on a valid query execution" do
        query.name="nome"
        query.description="descricao"
        query.sql="SELECT students.name as name FROM students\r\nWHERE students.created_at < :data_consulta"
        parameter = query.params.new
        parameter.name="data_consulta"
        parameter.value_type="Date"
        expect(query).to be_valid
      end	      
    end
  end

end

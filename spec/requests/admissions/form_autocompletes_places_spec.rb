# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O autocomplete dos campos de cidade, estado, pais, instituicao e curso do
# formulario de inscricao so tinha a rota form_field coberta
# (form_autocompletes_spec.rb). Sem cobertura (#720): state, country,
# institution e course. A rota e publica: o candidato chama sem login.
RSpec.describe "Autocomplete de lugares e cursos da inscricao", type: :request do
  before(:each) do
    @brasil = FactoryBot.create(:country, name: "Brasil")
    @argentina = FactoryBot.create(:country, name: "Argentina")
    FactoryBot.create(:state, name: "Rio de Janeiro", code: "RJ", country: @brasil)
    FactoryBot.create(:state, name: "Rio Grande do Sul", code: "RS", country: @brasil)
    FactoryBot.create(:state, name: "Rio Negro", code: "RN-AR", country: @argentina)
    @uff = FactoryBot.create(:institution, name: "Universidade Federal Fluminense")
    @ufrj = FactoryBot.create(:institution, name: "Universidade Federal do Rio de Janeiro")
    FactoryBot.create(:major, name: "Ciencia da Computacao", institution: @uff)
    FactoryBot.create(:major, name: "Ciencia da Computacao", institution: @ufrj)
    FactoryBot.create(:major, name: "Engenharia de Computacao", institution: @ufrj)
  end

  def nomes
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    JSON.parse(response.body)
  end

  describe "GET state" do
    it "procura por trecho do nome, sem login" do
      get state_form_autocompletes_path, params: { term: "Rio" }

      expect(nomes).to contain_exactly("Rio de Janeiro", "Rio Grande do Sul", "Rio Negro")
    end

    it "restringe ao pais informado" do
      get state_form_autocompletes_path, params: { term: "Rio", country: "Arg" }

      expect(nomes).to eq(["Rio Negro"])
    end
  end

  describe "GET country" do
    it "procura por trecho do nome" do
      get country_form_autocompletes_path, params: { term: "ras" }

      expect(nomes).to eq(["Brasil"])
    end
  end

  describe "GET institution" do
    it "procura por trecho do nome" do
      get institution_form_autocompletes_path, params: { term: "Fluminense" }

      expect(nomes).to eq(["Universidade Federal Fluminense"])
    end
  end

  describe "GET course" do
    it "devolve cada nome uma vez so, mesmo em instituicoes diferentes" do
      get course_form_autocompletes_path, params: { term: "Computacao" }

      expect(nomes).to contain_exactly("Ciencia da Computacao", "Engenharia de Computacao")
    end

    it "restringe a instituicao informada" do
      get course_form_autocompletes_path, params: { term: "Computacao", institution: "Fluminense" }

      expect(nomes).to eq(["Ciencia da Computacao"])
    end

    # ignore_association: instituicao sem curso que case nao esvazia a lista.
    it "ignora a instituicao quando ela nao tem curso que case" do
      get course_form_autocompletes_path, params: { term: "Engenharia", institution: "Fluminense" }

      expect(nomes).to eq(["Engenharia de Computacao"])
    end
  end
end

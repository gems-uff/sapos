# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Projeto e artigo pertencem a um professor, e o professor logado nao pode
# passa-los para outro. A validacao le current_user, que so existe numa
# requisicao, e nenhum exemplo a percorria (#720).
RSpec.describe "Dono de projeto e artigo editado pelo professor", type: :request do
  before(:each) do
    @eu = FactoryBot.create(:professor, name: "Prof Dono")
    @outro = FactoryBot.create(:professor, name: "Prof Outro")
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_professor)], "prof_dono@ic.uff.br", "Prof Dono", professor: @eu
    )
  end

  describe "projeto" do
    before(:each) do
      @projeto = FactoryBot.create(:grant, professor: @eu, title: "Projeto Original")
    end

    it "recusa trocar o professor do proprio projeto" do
      put grant_path(@projeto), params: { record: { title: "Projeto Original", professor: @outro.id } }

      expect(@projeto.reload.professor).to eq(@eu)
      expect(response.body).to include(
        CGI.escapeHTML(Grant.new.errors.generate_message(:professor, :cannot_edit_other_grants))
      )
    end

    it "aceita editar o titulo mantendo o professor" do
      put grant_path(@projeto), params: { record: { title: "Projeto Renomeado", professor: @eu.id } }

      expect(response).to have_http_status(:found)
      expect(@projeto.reload.title).to eq("Projeto Renomeado")
    end
  end

  describe "artigo" do
    before(:each) do
      @artigo = FactoryBot.create(:paper, owner: @eu, reference: "Artigo Original")
    end

    it "recusa trocar o dono do proprio artigo" do
      put paper_path(@artigo), params: { record: { reference: "Artigo Original", owner: @outro.id } }

      expect(@artigo.reload.owner).to eq(@eu)
      expect(response.body).to include(
        CGI.escapeHTML(Paper.new.errors.generate_message(:owner, :cannot_edit_other_papers))
      )
    end

    it "aceita editar a referencia mantendo o dono" do
      put paper_path(@artigo), params: { record: { reference: "Artigo Revisto", owner: @eu.id } }

      expect(response).to have_http_status(:found)
      expect(@artigo.reload.reference).to eq("Artigo Revisto")
    end
  end
end

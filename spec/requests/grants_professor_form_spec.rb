# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Professor cadastra projeto so em nome proprio: sem :edit_professor, o
# GrantsHelper#professor_form_column troca o record_select por um rotulo com o
# nome e um campo oculto com o id (#720). A suite so abria o formulario como
# administrador.
RSpec.describe "Projeto cadastrado pelo professor", type: :request do
  before(:each) do
    @professor = FactoryBot.create(:professor, name: "Professora Projetos")
  end

  def html
    Nokogiri::HTML(response.body)
  end

  describe "professor" do
    before(:each) do
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_professor)], "prof_projetos@ic.uff.br", "Prof",
        professor: @professor
      )
    end

    def confere_professor_fixo
      expect(html.css("input.recordselect[name='record[professor]']")).to be_empty
      oculto = html.css("input[type='hidden'][name='record[professor]']").first
      expect(oculto["value"]).to eq(@professor.id.to_s)
      expect(html.css("label").map { |l| l.text.strip }).to include("Professora Projetos")
    end

    it "o novo projeto vem com o proprio professor, sem escolha" do
      get new_grant_path

      expect(response).to have_http_status(:ok)
      confere_professor_fixo
    end

    it "a edicao do proprio projeto mantem o professor fixo" do
      projeto = FactoryBot.create(:grant, professor: @professor)

      get edit_grant_path(projeto)

      expect(response).to have_http_status(:ok)
      confere_professor_fixo
    end
  end

  # Controle: o administrador escolhe o professor pelo record_select.
  it "o administrador escolhe o professor" do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_projetos@ic.uff.br", "Adm"
    )

    get new_grant_path

    expect(response).to have_http_status(:ok)
    campo = html.css("input.recordselect[name='record[professor]']").first
    expect(campo["data-rs-url"]).to eq("/professors/browse")
  end
end

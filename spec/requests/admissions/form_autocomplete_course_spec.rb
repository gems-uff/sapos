# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O autocomplete de curso do formulario de inscricao filtra pela instituicao
# digitada e, quando ela nao casa curso nenhum, refaz a busca so pelo nome
# (ignore_association). O segundo passo nao tinha exemplo (#720).
RSpec.describe "Admissions::FormAutocompletes course", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "autocomplete_curso@ic.uff.br", "Adm"
    )
    uff = FactoryBot.create(:institution, name: "Universidade Federal Fluminense")
    FactoryBot.create(:major, name: "Ciencia da Computacao", institution: uff)
    FactoryBot.create(:major, name: "Engenharia Civil", institution: uff)
  end

  it "sugere pelo nome quando a instituicao digitada nao tem o curso" do
    get course_form_autocompletes_path, params: { term: "computacao", institution: "Instituto Sem Cursos" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq(["Ciencia da Computacao"])
  end

  it "filtra pela instituicao quando ela tem o curso" do
    get course_form_autocompletes_path, params: { term: "a", institution: "Fluminense" }

    expect(JSON.parse(response.body)).to contain_exactly("Ciencia da Computacao", "Engenharia Civil")
  end
end

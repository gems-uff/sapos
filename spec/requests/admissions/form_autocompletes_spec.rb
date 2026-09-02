# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O autocomplete de campos de formulário de admissão repassa params[:term] direto
# para o modelo. Sem o parâmetro, o termo chegava nil e a busca por substring
# fazia name.include?(nil) -- TypeError, HTTP 500 e uma notificação de exceção por
# e-mail a cada ocorrência (#623).
#
# Estes exemplos batem na rota, que é a reprodução literal da issue: o defeito
# estava no modelo, mas quem o alcançava era o controller, e nada na suíte passava
# por aqui.
RSpec.describe "Admissions::FormAutocompletes", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "autocomplete_admin@ic.uff.br")
    sign_in @admin
    @form_template = FactoryBot.create(:form_template)
    @campo = FactoryBot.create(
      :form_field, name: "campo_de_teste", form_template: @form_template
    )
  end

  describe "GET form_field" do
    it "responde vazio quando o term não é enviado" do
      get form_field_form_autocompletes_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "responde vazio quando o term vem em branco" do
      get form_field_form_autocompletes_path, params: { term: "" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "sugere o campo gravado quando o term casa" do
      get form_field_form_autocompletes_path, params: { term: "de_teste" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("campo_de_teste")
    end
  end
end

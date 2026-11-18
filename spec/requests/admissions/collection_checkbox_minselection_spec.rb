# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Checkbox Multiplo com minimo e sem maximo (issue #605): o script que confere
# o minimo no navegador so e gerado quando ha maximo; o servidor confere sempre.
RSpec.describe "Minimo do Checkbox Multiplo no navegador", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.minsel@ic.uff.br", "Adm")
  end

  def template_com(config)
    create_admission_template("Minimo #{SecureRandom.hex(3)}", {
      "Opcoes" => { field_type: Admissions::FormField::COLLECTION_CHECKBOX,
                    configuration: { values: ["a", "b", "c"] }.merge(config) },
    })
  end

  def pagina(config)
    get preview_form_template_path(template_com(config))
    response.body
  end

  let(:aviso) do
    I18n.t("activerecord.errors.models.admissions/filled_form_field.minselection", count: 2).to_json[1..-2]
  end

  it "controle: com maximo, a pagina confere o minimo" do
    expect(pagina(minselection: 2, maxselection: 3)).to include(aviso)
  end

  it "controle: sem maximo, o servidor recusa uma opcao so" do
    t = template_com(minselection: 2)
    post preview_form_template_path(t), params: { record: {
      form_template_id: t.id, fields_attributes: { "0" => { form_field_id: t.fields.first.id, list: ["", "a"] } },
    } }
    expect(Nokogiri::HTML(response.body).at_css("#errorExplanation")).to be_present
  end

  it "sem maximo, a pagina confere o minimo", pending: "issue #605" do
    expect(pagina(minselection: 2)).to include(aviso)
  end
end

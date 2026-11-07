# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O campo de escolaridade da candidatura acrescenta e remove itens pelo cocoon
# (link_to_add_association e link_to_remove_association), e nenhum exemplo
# clicava nesses links (#720). O cocoon e so JavaScript mais o template que o
# helper embute no link: um update dele, ou do jQuery que ele usa, quebra o
# formulario do candidato sem tocar em linha nenhuma de Ruby.
RSpec.describe "Escolaridade da candidatura pelo cocoon", type: :feature, js: true do
  before(:each) do
    template = FactoryBot.create(:form_template, name: "Inscricao")
    campo = FactoryBot.create(
      :form_field, form_template: template, name: "Formacao",
      field_type: Admissions::FormField::SCHOLARITY,
      configuration: { values: ["Graduação", "Mestrado"], statuses: ["Completo", "Em andamento"] }.to_json
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado", simple_url: "cocoon-#{SecureRandom.hex(4)}",
      form_template: template, start_date: Date.today - 10.days,
      end_date: Date.today + 10.days, edit_date: Date.today + 20.days
    )
    filled_form = FactoryBot.create(:filled_form, form_template: template, is_filled: true)
    @preenchido = FactoryBot.create(
      :filled_form_field, filled_form: filled_form, form_field: campo, value: nil
    )
    @antigo = FactoryBot.create(
      :filled_form_field_scholarity, filled_form_field: @preenchido,
      level: "Graduação", institution: "Instituicao Antiga", location: "Niteroi, RJ"
    )
    @application = FactoryBot.create(
      :admission_application, admission_process: @process, filled_form: filled_form
    )
    visit edit_admission_apply_path(admission_id: @process.simple_id, id: @application.token)
  end

  def itens_visiveis = all(".scholarity", visible: true)

  it "acrescenta um item vazio ao clicar em adicionar" do
    expect(itens_visiveis.size).to eq(1)

    click_link "Adicionar formação"

    expect(page).to have_selector(".scholarity", count: 2, visible: true)
    expect(itens_visiveis.last.find("input.scholarity-institution").value).to eq("")
  end

  it "esconde o item ao clicar em remover" do
    within(itens_visiveis.first) { click_link "Remover formação" }

    expect(page).to have_selector(".scholarity", count: 0, visible: true)
  end

  it "grava o item acrescentado e apaga o removido" do
    click_link "Adicionar formação"
    expect(page).to have_selector(".scholarity", count: 2, visible: true)
    itens_visiveis.last.find("input.scholarity-institution").set("Instituicao Nova")
    within(itens_visiveis.first) { click_link "Remover formação" }
    expect(page).to have_selector(".scholarity", count: 1, visible: true)

    find("input[type=submit]", match: :first).click
    expect(page).to have_no_current_path(/edit/)

    instituicoes = Admissions::FilledFormFieldScholarity
      .where(filled_form_field_id: @preenchido.id).pluck(:institution)
    expect(instituicoes).to eq(["Instituicao Nova"])
  end
end

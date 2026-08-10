# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O widget de condicao (app/assets/javascripts/form_widgets/form_condition_widget.js)
# monta os campos escondidos que carregam mode, field, condition e value. Ate aqui
# nenhum spec o abria num navegador: os de model exercitam a validacao, mas nao o
# JavaScript que produz o que o formulario envia. Sem isto, trocar a montagem
# desses campos passa verde mesmo quebrando a tela.
RSpec.describe "AdmissionPhases features", type: :feature do
  let(:url_path) { "/admission_phases" }
  let(:plural_name) { "admissions__admission_phases" }
  let(:model) { Admissions::AdmissionPhase }
  let(:widget) { "#widget_record_approval_condition_" }

  # before(:all) porque o servidor do Capybara roda em outra conexao e nao
  # enxergaria dado nao commitado. Sem limpeza manual: a varredura pos-grupo
  # apaga o que sobrar (AGENTS.md, #643).
  before(:all) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm])
    # A condicao so valida se o nome do campo existir de fato
    # (Admissions::FormCondition#that_field_name_exists).
    @field = FactoryBot.create(:form_field, name: "campo_a")
  end

  describe "condition widget", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    # O `change` e o gatilho que grava o valor digitado no estado do widget; o
    # blur do Capybara nao e garantia de dispara-lo.
    def set_and_change(selector, value)
      find(selector).set(value)
      page.execute_script("$('#{selector}').trigger('change')")
    end

    it "should save a single condition" do
      name = "Fase condicao simples"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: name
      end

      find("#{widget} > .mode > select").select("Condição")
      set_and_change("#{widget} > .sub > .field-input", "campo_a")
      set_and_change("#{widget} > .sub > .value-input", "aprovado")

      click_button_and_wait "Salvar"
      # A gravacao tem de ser confirmada na tela: se a condicao chegar invalida
      # ao servidor o formulario permanece com o erro, e buscar o registro pelo
      # nome logo abaixo e o que impede o exemplo de se apoiar no que o outro
      # exemplo do grupo deixou gravado.
      expect(page).to have_css("td.name-column", text: name)

      phase = model.find_by(name: name)
      expect(phase).not_to be_nil
      condition = phase.approval_condition
      expect(condition).not_to be_nil
      expect(condition.mode).to eq Admissions::FormCondition::CONDITION
      expect(condition.field).to eq "campo_a"
      expect(condition.value).to eq "aprovado"
    end

    # O modo "E" e o outro ramo do widget: o cabecalho de campos escondidos e
    # remontado e cada filho ganha os seus, com nome derivado do pai.
    it "should save a composed condition with a child" do
      name = "Fase condicao composta"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: name
      end

      find("#{widget} > .mode > select").select("E")

      child = "#{widget} > .sub > .items > .form-condition-widget"
      expect(page).to have_css(child)
      set_and_change("#{child} > .sub > .field-input", "campo_a")
      set_and_change("#{child} > .sub > .value-input", "aprovado")

      click_button_and_wait "Salvar"
      expect(page).to have_css("td.name-column", text: name)

      phase = model.find_by(name: name)
      expect(phase).not_to be_nil
      condition = phase.approval_condition
      expect(condition).not_to be_nil
      expect(condition.mode).to eq Admissions::FormCondition::AND
      expect(condition.form_conditions.size).to eq 1

      child_condition = condition.form_conditions.first
      expect(child_condition.mode).to eq Admissions::FormCondition::CONDITION
      expect(child_condition.field).to eq "campo_a"
      expect(child_condition.value).to eq "aprovado"
    end
  end
end

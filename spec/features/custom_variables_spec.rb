# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CustomVariables features", type: :feature do
  let(:url_path) { "/custom_variables" }
  let(:plural_name) { "custom_variables" }
  let(:model) { CustomVariable }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @record = FactoryBot.create(:custom_variable, variable: "single_advisor_points", value: "1.0")
    @destroy_all << FactoryBot.create(:custom_variable, variable: "minimum_grade_for_approval", value: "6.0")
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
    UserRole.delete_all
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Variáveis"
      expect(page.all("tr th").map(&:text)).to eq [
        "Variável", "Valor", "Descrição", ""
      ]
    end

    it "should sort the list by variable, asc" do
      expect(page.all("tr td.variable-column").map(&:text)).to eq ["minimum_grade_for_approval", "single_advisor_points"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert and remove record" do
      # Insert record
      expect(page).to have_content "Adicionar Variável"
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_variable_").find(:option, text: "identity_issuing_country").select_option
        fill_in "Valor", with: "Brasil"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.variable-column", text: "identity_issuing_country")

      # Remove inserted record
      expect(page.all("tr td.variable-column").map(&:text)).to eq ["identity_issuing_country", "minimum_grade_for_approval", "single_advisor_points"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.variable-column").map(&:text)).to eq ["minimum_grade_for_approval", "single_advisor_points"]
    end

    it "should have a selection for variable options" do
      expect(page.all("select#record_variable_ option").map(&:text)).to eq ([""] + CustomVariable::VARIABLES.keys)
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit student" do
      within(".as_form") do
        fill_in "Descrição", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.description-column", text: "Teste")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by variable" do
      fill_in "search", with: "singl"
      sleep(0.8)
      expect(page.all("tr td.variable-column").map(&:text)).to eq ["single_advisor_points"]
    end
  end
end

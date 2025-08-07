# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EnrollmentStatuses features", type: :feature do
  let(:url_path) { "/enrollment_statuses" }
  let(:plural_name) { "enrollment_statuses" }
  let(:model) { EnrollmentStatus }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])
    @destroy_all << @record = FactoryBot.create(:enrollment_status, name: "Especial", user: true)
    @destroy_all << FactoryBot.create(:enrollment_status, name: "Avulso", user: false)
    @destroy_all << FactoryBot.create(:enrollment_status, name: "Regular", user: true)
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
      expect(page).to have_content "Tipos de Matrícula"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Com usuário", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Avulso", "Especial", "Regular"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Adicionar"
    end

    it "should be able to insert and remove records" do
      # Insert record
      expect(page).to have_content "Adicionar Tipo de Matrícula"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Novo"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Novo")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Novo", "Avulso", "Especial", "Regular"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Avulso", "Especial", "Regular"]
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
        fill_in "Nome", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Avul"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Avulso"]
    end
  end
end

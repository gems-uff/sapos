# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Advisements features", type: :feature do
  let(:url_path) { "/advisement_authorizations" }
  let(:plural_name) { "advisement_authorizations" }
  let(:model) { AdvisementAuthorization }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Erica", cpf: "3")
    @destroy_all << @professor2 = FactoryBot.create(:professor, name: "Fiona", cpf: "2")
    @destroy_all << @professor3 = FactoryBot.create(:professor, name: "Gi", cpf: "1")
    @destroy_all << @professor4 = FactoryBot.create(:professor, name: "Helena", cpf: "4")

    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor1, level: @level1)
    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor2, level: @level2)
    @destroy_all << @record = FactoryBot.create(:advisement_authorization, professor: @professor3, level: @level1)

    @destroy_all << @user = create_confirmed_user([@role_adm])
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @role_adm.delete
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
      expect(page).to have_content "Credenciamentos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Orientador", "Nível", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.professor-column").map(&:text)).to eq ["Erica", "Fiona", "Gi"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Adicionar"
    end

    it "should be able to insert and remove record" do
      # Insert record
      expect(page).to have_content "Adicionar Credenciamento"
      fill_record_select("professor_", "professors", "Helena")
      find(:select, "record_level_").find(:option, text: @level2.name).select_option
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.professor-column", text: "Helena")

      # Remove inserted record
      expect(page.all("tr td.professor-column").map(&:text)).to eq ["Helena", "Erica", "Fiona", "Gi"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.professor-column").map(&:text)).to eq ["Erica", "Fiona", "Gi"]
    end

    it "should have a record_select widget for professor" do
      expect_to_have_record_select(page, "professor_", "professors")
    end

    it "should have a selection for level options" do
      expect(page.all("select#record_level_ option").map(&:text)).to eq ["Selecione uma opção", "Doutorado", "Mestrado"]
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit record" do
      within(".as_form") do
        find(:select, "record_level_#{@record.id}").find(:option, text: @level1.name).select_option
      end
      click_button "Atualizar"
      expect(page).to have_css("#as_#{plural_name}-list-#{@record.id}-row td.level-column", text: "Doutorado")
      @record.level = @level2
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
      sleep(0.2)
    end

    it "should be able to search by advisor" do
      search_record_select("professor", "professors", "Erica")
      click_button "Buscar"
      expect(page.all("tr td.professor-column").map(&:text)).to eq ["Erica"]
    end

    it "should be able to search by level" do
      page.send_keys :escape
      find(:select, "search_level").find(:option, text: "Doutorado").select_option
      click_button "Buscar"
      expect(page.all("tr td.professor-column").map(&:text)).to eq ["Erica", "Gi"]
    end
  end
end

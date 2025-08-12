# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Todo: test students?

RSpec.describe "Majors features", type: :feature do
  let(:url_path) { "/majors" }
  let(:plural_name) { "majors" }
  let(:model) { Major }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @level3 = FactoryBot.create(:level, name: "Graduação")

    @destroy_all << @institution1 = FactoryBot.create(:institution, name: "Universidade Federal Fluminense", code: "UFF")
    @destroy_all << @institution2 = @record = FactoryBot.create(:institution, name: "Universidade Estadual do Rio de Janeiro", code: "UERJ")

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")

    @destroy_all << @major1 = FactoryBot.create(:major, name: "Ciência da Computação", level: @level3, institution: @institution1)
    @destroy_all << FactoryBot.create(:major, name: "Sistemas de Informação", level: @level3, institution: @institution1)
    @destroy_all << @record = FactoryBot.create(:major, name: "Ciência da Computação", level: @level3, institution: @institution2)

    @destroy_all << FactoryBot.create(:student_major, major: @major1, student: @student1)
    @destroy_all << FactoryBot.create(:student_major, major: @major1, student: @student2)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Cursos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Nível", "Instituição", "Alunos", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Ciência da Computação", "Ciência da Computação", "Sistemas de Informação"]
    end

    it "should show a list of students" do
      expect(page).to have_css("#as_#{plural_name}-list-#{@major1.id}-row td.students-column", text: "Ana, Bia")
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
      expect(page).to have_content "Adicionar Curso"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Tecnologia em Sistemas de Computação"
        find(:select, "record_level_").find(:option, text: @level3.name).select_option
      end
      fill_record_select("institution_", "institutions", "Flum")
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Tecnologia em Sistemas de Computação")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Tecnologia em Sistemas de Computação", "Ciência da Computação", "Ciência da Computação", "Sistemas de Informação"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Ciência da Computação", "Ciência da Computação", "Sistemas de Informação"]
    end

    it "should have a record_select widget for professor" do
      expect_to_have_record_select(page, "institution_", "institutions")
    end

    it "should have a selection for level options" do
      expect(page.all("select#record_level_ option").map(&:text)).to eq ["Selecione uma opção", "Doutorado", "Graduação", "Mestrado"]
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
      fill_in "search", with: "Sis"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Sistemas de Informação"]
    end
  end
end

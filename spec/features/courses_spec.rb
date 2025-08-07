# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: insert research area

RSpec.describe "Courses features", type: :feature do
  let(:url_path) { "/courses" }
  let(:plural_name) { "courses" }
  let(:model) { Course }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @course_type1 = FactoryBot.create(:course_type, name: "Obrigatória", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false)
    @destroy_all << @course_type2 = FactoryBot.create(:course_type, name: "Pesquisa", has_score: false, schedulable: true, show_class_name: false, allow_multiple_classes: true, on_demand: true)
    @destroy_all << @course_type3 = FactoryBot.create(:course_type, name: "Tópicos", has_score: true, schedulable: true, show_class_name: true, allow_multiple_classes: true, on_demand: false)
    @destroy_all << @course_type4 = FactoryBot.create(:course_type, name: "Defesa", has_score: false, schedulable: false, show_class_name: false, allow_multiple_classes: false, on_demand: false)

    @destroy_all << @research_area1 = FactoryBot.create(:research_area, name: "Ciência de Dados", code: "CD")
    @destroy_all << @research_area2 = FactoryBot.create(:research_area, name: "Sistemas de Computação", code: "SC")
    @destroy_all << @research_area3 = FactoryBot.create(:research_area, name: "Engenharia de Software", code: "ES")

    @destroy_all << FactoryBot.create(:course, name: "Algebra", code: "C1", credits: 4, workload: 60, course_type: @course_type1, available: true)
    @destroy_all << FactoryBot.create(:course, name: "Algebra", code: "C1-old", credits: 4, workload: 60, course_type: @course_type1, available: false)
    @destroy_all << @course3 = FactoryBot.create(:course, name: "Versionamento", code: "C2", credits: 4, workload: 60, course_type: @course_type1, available: true)
    @destroy_all << @record = FactoryBot.create(:course, name: "Defesa", code: "C3", credits: 72, workload: 1080, course_type: @course_type4, available: true)
    @destroy_all << @course5 = FactoryBot.create(:course, name: "Tópicos em ES", code: "C4", credits: 4, workload: 60, course_type: @course_type3, available: true)
    @destroy_all << FactoryBot.create(:course, name: "Pesquisa", code: "C5", credits: 0, workload: 0, course_type: @course_type2, available: true)

    @destroy_all << FactoryBot.create(:course_research_area, course: @course3, research_area: @research_area3)
    @destroy_all << FactoryBot.create(:course_research_area, course: @course5, research_area: @research_area3)
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
      expect(page).to have_content "Disciplinas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Código", "Áreas de Pesquisa", "Créditos", "Carga Horária", "Tipo de Disciplina", "Disciplina do currículo vigente", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra", "Algebra", "Defesa", "Pesquisa", "Tópicos em ES", "Versionamento"]
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
      expect(page).to have_content "Adicionar Disciplina"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Programação"
        fill_in "Código", with: "C6"
        fill_in "Créditos", with: "4"
        fill_in "Carga Horária", with: "60"
        find(:select, "record_course_type_").find(:option, text: @course_type1.name).select_option
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Programação")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Programação", "Algebra", "Algebra", "Defesa", "Pesquisa", "Tópicos em ES", "Versionamento"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra", "Algebra", "Defesa", "Pesquisa", "Tópicos em ES", "Versionamento"]
    end

    it "should have a selection for course_type options" do
      expect(page.all("select#record_course_type_ option").map(&:text)).to eq ["Selecione uma opção", "Defesa", "Obrigatória", "Pesquisa", "Tópicos"]
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
      @record.name = "Defesa"
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "Nome", with: "Ver"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Versionamento"]
    end

    it "should be able to search by course_type" do
      expect(page.all("select#search_course_type option").map(&:text)).to eq ["Selecione uma opção", "Defesa", "Obrigatória", "Pesquisa", "Tópicos"]
      find(:select, "search_course_type").find(:option, text: "Tópicos").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Tópicos em ES"]
    end

    it "should be able to search by research_area" do
      fill_in "Áreas de Pesquisa", with: "Engenharia de Software"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Tópicos em ES", "Versionamento"]
    end

    it "should be able to search by availability" do
      expect(page.all("select#search_available option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_available").find(:option, text: "Não").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra"]
    end
  end
end

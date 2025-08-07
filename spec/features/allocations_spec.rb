# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Allocations features", type: :feature do
  let(:url_path) { "/allocations" }
  let(:plural_name) { "allocations" }
  let(:model) { Allocation }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @course_type1 = FactoryBot.create(:course_type, name: "Obrigatória", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false)
    @destroy_all << @course_type3 = FactoryBot.create(:course_type, name: "Tópicos", has_score: true, schedulable: true, show_class_name: true, allow_multiple_classes: true, on_demand: false)

    @destroy_all << @research_area3 = FactoryBot.create(:research_area, name: "Engenharia de Software", code: "ES")

    @destroy_all << @course1 = FactoryBot.create(:course, name: "Algebra", code: "C1", credits: 4, workload: 60, course_type: @course_type1, available: true)
    @destroy_all << @course2 = FactoryBot.create(:course, name: "Algebra", code: "C1-old", credits: 4, workload: 60, course_type: @course_type1, available: false)
    @destroy_all << @course3 = FactoryBot.create(:course, name: "Versionamento", code: "C2", credits: 4, workload: 60, course_type: @course_type1, available: true)
    @destroy_all << @course5 = FactoryBot.create(:course, name: "Tópicos em ES", code: "C4", credits: 4, workload: 60, course_type: @course_type3, available: true)
    @destroy_all << @course7 = FactoryBot.create(:course, name: "Programação", code: "C6", credits: 4, workload: 60, course_type: @course_type1, available: true)

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Erica", cpf: "3")
    @destroy_all << @professor2 = FactoryBot.create(:professor, name: "Fiona", cpf: "2")
    @destroy_all << @professor3 = FactoryBot.create(:professor, name: "Gi", cpf: "1")
    @destroy_all << @professor4 = FactoryBot.create(:professor, name: "Helena", cpf: "4")

    @destroy_all << @course_class1 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 1)
    @destroy_all << @course_class2 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 2)
    @destroy_all << @course_class3 = FactoryBot.create(:course_class, name: "Algebra", course: @course2, professor: @professor1, year: 2021, semester: 2)
    @destroy_all << @course_class4 = FactoryBot.create(:course_class, name: "Versionamento", course: @course3, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @course_class6 = FactoryBot.create(:course_class, name: "Mineração de Repositórios", course: @course5, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @course_class7 = FactoryBot.create(:course_class, name: "Programação", course: @course7, professor: @professor1, year: 2022, semester: 2)

    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class2, day: "Segunda", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class2, day: "Segunda", start_time: 14, end_time: 16)
    @destroy_all << @record = FactoryBot.create(:allocation, course_class: @course_class4, day: "Segunda", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class4, day: "Quarta", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class6, day: "Terça", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class6, day: "Quinta", start_time: 11, end_time: 13)
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
      expect(page).to have_content "Alocações"
      expect(page.all("tr th").map(&:text)).to eq [
        "Turma", "Dia", "Sala", "Hora de início", "Hora de fim", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.course_class-column").map(&:text)).to eq ["Algebra - 2022/2", "Algebra - 2022/2", "Versionamento - 2022/2", "Versionamento - 2022/2", "Tópicos em ES (Mineração de Repositórios) - 2022/2", "Tópicos em ES (Mineração de Repositórios) - 2022/2"]
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
      expect(page).to have_content "Adicionar Alocação"
      fill_record_select("course_class_", "course_classes", "Programação")
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_day_").find(:option, text: "Quinta").select_option
        fill_in "Hora de início", with: "9"
        fill_in "Hora de fim", with: "11"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.course_class-column", text: "Programação - 2022/2")

      # Remove inserted record
      expect(page.all("tr td.course_class-column").map(&:text)).to eq ["Programação - 2022/2", "Algebra - 2022/2", "Algebra - 2022/2", "Versionamento - 2022/2", "Versionamento - 2022/2", "Tópicos em ES (Mineração de Repositórios) - 2022/2", "Tópicos em ES (Mineração de Repositórios) - 2022/2"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.course_class-column").map(&:text)).to eq ["Algebra - 2022/2", "Algebra - 2022/2", "Versionamento - 2022/2", "Versionamento - 2022/2", "Tópicos em ES (Mineração de Repositórios) - 2022/2", "Tópicos em ES (Mineração de Repositórios) - 2022/2"]
    end

    it "should show end_time_before_start_time error when end time occurs before start time" do
      # Insert record
      fill_record_select("course_class_", "course_classes", "Programação")
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_day_").find(:option, text: "Quinta").select_option
        fill_in "Hora de início", with: "11"
        fill_in "Hora de fim", with: "9"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_content "Hora de início menor do que a hora de fim"
    end

    it "should show scheduling_conflict error when end time occurs between other allocation" do
      # Insert record
      fill_record_select("course_class_", "course_classes", "Versionamento")
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_day_").find(:option, text: "Segunda").select_option
        fill_in "Hora de início", with: "10"
        fill_in "Hora de fim", with: "12"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_content "Hora de fim este horário já está sendo usado em outra alocação da mesma turma"
    end

    it "should have a selection for day" do
      expect(page.all("select#record_day_ option").map(&:text)).to eq ["Selecione uma opção", "Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
    end

    it "should have a record_select widget for course_class" do
      expect_to_have_record_select(page, "course_class_", "course_classes")
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
        fill_in "Sala", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.room-column", text: "Teste")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by day" do
      fill_in "search", with: "Segunda"
      sleep(0.8)
      expect(page.all("tr td.course_class-column").map(&:text)).to eq ["Algebra - 2022/2", "Algebra - 2022/2", "Versionamento - 2022/2"]
    end
  end
end

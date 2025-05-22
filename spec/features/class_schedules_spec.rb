# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ClassSchedules features", type: :feature do
  let(:url_path) { "/class_schedules" }
  let(:plural_name) { "class_schedules" }
  let(:model) { ClassSchedule }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << FactoryBot.create(
      :class_schedule, year: 2023, semester: 1,
      enrollment_start: DateTime.new(2023, 3, 20, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_end: DateTime.new(2023, 3, 23, 23, 59, 59, Time.zone.formatted_offset),
      period_start: DateTime.new(2023, 4, 3, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_insert: DateTime.new(2023, 4, 18, 23, 59, 59, Time.zone.formatted_offset),
      enrollment_remove: DateTime.new(2023, 5, 3, 23, 59, 59, Time.zone.formatted_offset),
      period_end: DateTime.new(2023, 6, 22, 0, 0, 0, Time.zone.formatted_offset),
      grades_deadline: DateTime.new(2023, 6, 29, 0, 0, 0, Time.zone.formatted_offset)
    )
    @destroy_all << @record = FactoryBot.create(
      :class_schedule, year: 2022, semester: 1,
      enrollment_start: DateTime.new(2022, 3, 14, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_end: DateTime.new(2022, 3, 17, 23, 59, 59, Time.zone.formatted_offset),
      period_start: DateTime.new(2022, 3, 28, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_insert: DateTime.new(2022, 4, 12, 23, 59, 59, Time.zone.formatted_offset),
      enrollment_remove: DateTime.new(2022, 4, 27, 23, 59, 59, Time.zone.formatted_offset),
      period_end: DateTime.new(2022, 5, 22, 0, 0, 0, Time.zone.formatted_offset),
      grades_deadline: DateTime.new(2022, 5, 29, 0, 0, 0, Time.zone.formatted_offset)
    )
    @destroy_all << FactoryBot.create(
      :class_schedule, year: 2022, semester: 2,
      enrollment_start: DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_end: DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset),
      period_start: DateTime.new(2022, 8, 22, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_insert: DateTime.new(2022, 9, 6, 23, 59, 59, Time.zone.formatted_offset),
      enrollment_remove: DateTime.new(2022, 9, 21, 23, 59, 59, Time.zone.formatted_offset),
      period_end: DateTime.new(2022, 10, 22, 0, 0, 0, Time.zone.formatted_offset),
      grades_deadline: DateTime.new(2022, 10, 29, 0, 0, 0, Time.zone.formatted_offset)
    )
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
      expect(page).to have_content "Quadros de Horários"
      expect(page.all("tr th").map(&:text)).to eq [
        "Ano", "Semestre", "Data de Início das Inscrições",
        "Data de Fim das Inscrições", "Data de Início do Período Letivo",
        "Data Limite para Adicionar Disciplinas",
        "Data Limite para Remover Disciplinas",
        "Data de Fim do Período Letivo",
        "Data Limite para Lançamento de Notas", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.semester-column").map(&:text)).to eq ["1", "1", "2"]
      expect(page.all("tr td.year-column").map(&:text)).to eq ["2023", "2022", "2022"]
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
      expect(page).to have_content "Adicionar Quadro de Horário"
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_year_").find(:option, text: YearSemester.current.year.to_s).select_option
        find(:select, "record_semester_").find(:option, text: YearSemester.current.semester.to_s).select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.year-column", text: YearSemester.current.year.to_s)

      # Remove inserted record
      expect(page.all("tr td.year-column").map(&:text)).to eq [YearSemester.current.year.to_s, "2023", "2022", "2022"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.year-column").map(&:text)).to eq ["2023", "2022", "2022"]
    end

    it "should have a datetime picker for enrollment_start" do
      expect(page).to have_css("input.enrollment_start-input.datetime_picker")
    end

    it "should have a datetime picker for enrollment_end" do
      expect(page).to have_css("input.enrollment_end-input.datetime_picker")
    end

    it "should have a datetime picker for period_start" do
      expect(page).to have_css("input.period_start-input.datetime_picker")
    end

    it "should have a datetime picker for enrollment_insert" do
      expect(page).to have_css("input.enrollment_insert-input.datetime_picker")
    end

    it "should have a datetime picker for enrollment_remove" do
      expect(page).to have_css("input.enrollment_remove-input.datetime_picker")
    end

    it "should have a datetime picker for period_end" do
      expect(page).to have_css("input.period_end-input.datetime_picker")
    end

    it "should have a datetime picker for grades_deadline" do
      expect(page).to have_css("input.grades_deadline-input.datetime_picker")
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
        fill_in "Data Limite para Remover Disciplinas", with: "15 Ago 2023 23:59:59"
      end
      click_button "Atualizar"
      expect(page).to have_css("td.enrollment_remove-column", text: "15 Ago 2023 23:59:59")
      @record.enrollment_remove = DateTime.new(2022, 4, 27, 23, 59, 59, Time.zone.formatted_offset)
      @record.save!
    end

    it "should be able to copy enrollment_start to period_start" do
      expect(find("input.period_start-input.datetime_picker").value).to eq "28 Mar 2022 00:00:00"
      click_link "Repetir Data de Início das Inscrições"
      expect(find("input.period_start-input.datetime_picker").value).to eq "14 Mar 2022 00:00:00"
    end

    it "should be able to copy enrollment_end to enrollment_insert" do
      expect(find("input.enrollment_insert-input.datetime_picker").value).to eq "12 Abr 2022 23:59:59"
      find("#set_same_record_enrollment_insert_#{@record.id}").click
      expect(find("input.enrollment_insert-input.datetime_picker").value).to eq "17 Mar 2022 23:59:59"
    end

    it "should be able to copy enrollment_end to enrollment_remove" do
      expect(find("input.enrollment_remove-input.datetime_picker").value).to eq "27 Abr 2022 23:59:59"
      find("#set_same_record_enrollment_remove_#{@record.id}").click
      expect(find("input.enrollment_remove-input.datetime_picker").value).to eq "17 Mar 2022 23:59:59"
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      find(:select, "search_year").find(:option, text: "2022").select_option
      click_button "Buscar"
      expect(page.all("tr td.year-column").map(&:text)).to eq ["2022", "2022"]
    end
  end

  describe "class_schedule report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download a class schedule for a record" do
      find("#as_#{plural_name}-class_schedule_pdf-#{@record.id}-link").click

      wait_for_download
      expect(download).to match(/QUADRO DE HORÁRIOS \(2022_1\)\.pdf/)
    end
  end
end

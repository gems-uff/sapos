# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Accomplishments features", type: :feature do
  let(:url_path) { "/accomplishments" }
  let(:plural_name) { "accomplishments" }
  let(:model) { Accomplishment }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")

    @destroy_all << @phase1 = FactoryBot.create(:phase, name: "Artigo A1")
    @destroy_all << @phase2 = FactoryBot.create(:phase, name: "Pedido de Banca")
    @destroy_all << @phase3 = FactoryBot.create(:phase, name: "Exame de Qualificação")

    @destroy_all << FactoryBot.create(:phase_duration, level: @level2, phase: @phase2, deadline_months: 3, deadline_days: 0)
    @destroy_all << FactoryBot.create(:phase_duration, level: @level1, phase: @phase2, deadline_months: 3, deadline_days: 0)
    @destroy_all << FactoryBot.create(:phase_duration, level: @level1, phase: @phase3, deadline_months: 3, deadline_days: 0)

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student2, level: @level2, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level1, enrollment_status: @enrollment_status)

    @destroy_all << @record = FactoryBot.create(:accomplishment, enrollment: @enrollment2, phase: @phase2, conclusion_date: Date.today)
    @destroy_all << FactoryBot.create(:accomplishment, enrollment: @enrollment1, phase: @phase2, conclusion_date: Date.today)
    @destroy_all << FactoryBot.create(:accomplishment, enrollment: @enrollment3, phase: @phase2, conclusion_date: Date.today)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
    PhaseCompletion.delete_all
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Realização de Etapas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Matrícula", "Etapa", "Data de conclusão", "Observação", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia", "M01 - Ana", "M03 - Carol"]
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
      expect(page).to have_content "Adicionar Realização de Etapa"
      fill_record_select("enrollment_", "enrollments", "M04")
      page.send_keys :escape
      within("#as_#{plural_name}-create--form") do
        select_month_year_i("record_conclusion_date", Date.today)
        find(:select, "record_phase_").find(:option, text: "Pedido de Banca").select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04 - Dani")

      # Remove inserted record
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M04 - Dani", "M02 - Bia", "M01 - Ana", "M03 - Carol"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia", "M01 - Ana", "M03 - Carol"]
    end

    it "should show enrollment_level error when phase does not include enrollment level" do
      # Insert record
      page.send_keys :escape
      within("#as_#{plural_name}-create--form") do
        select_month_year_i("record_conclusion_date", Date.today)
        find(:select, "record_phase_").find(:option, text: "Exame de Qualificação").select_option
      end
      fill_record_select("enrollment_", "enrollments", "M01")
      click_button "Salvar"
      expect(page).to have_content "Matrícula não possui o mesmo nível que a etapa"
    end

    it "should have a record_select widget for enrollment" do
      expect_to_have_record_select(page, "enrollment_", "enrollments")
    end

    it "should have a month_year widget for conclusion_date" do
      page.send_keys :escape
      expect_to_have_month_year_widget_i(page, "conclusion_date")
    end

    it "should have a selection for phase options" do
      page.send_keys :escape
      expect(page.all("select#record_phase_ option").map(&:text)).to eq ["Selecione uma opção", "Artigo A1", "Exame de Qualificação", "Pedido de Banca"]
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit student" do
      page.send_keys :escape
      date = 3.months.from_now
      within(".as_form") do
        select_month_year_i("record_conclusion_date", date)
      end
      click_button "Atualizar"
      expect(page).to have_css("#as_#{plural_name}-list-#{@record.id}-row td.conclusion_date-column", text: I18n.l(date, format: "%B-%Y"))
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by enrollment number" do
      fill_in "search", with: "M02"
      sleep(0.8)
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end
  end
end

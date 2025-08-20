# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Deferrals features", type: :feature do
  let(:url_path) { "/deferrals" }
  let(:plural_name) { "deferrals" }
  let(:model) { Deferral }
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

    @destroy_all << @deferral_type1 = FactoryBot.create(:deferral_type, name: "Extraordinária", phase: @phase2)
    @destroy_all << @deferral_type2 = FactoryBot.create(:deferral_type, name: "Regular", phase: @phase2)
    @destroy_all << @deferral_type3 = FactoryBot.create(:deferral_type, name: "Final", phase: @phase2)

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student2, level: @level2, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level1, enrollment_status: @enrollment_status)


    @destroy_all << @record = FactoryBot.create(:deferral, deferral_type: @deferral_type2, enrollment: @enrollment2, approval_date: Date.today)
    @destroy_all << FactoryBot.create(:deferral, deferral_type: @deferral_type2, enrollment: @enrollment1, approval_date: Date.today)
    @destroy_all << FactoryBot.create(:deferral, deferral_type: @deferral_type2, enrollment: @enrollment3, approval_date: Date.today)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    PhaseCompletion.delete_all
    @destroy_all.each(&:delete)
    @destroy_all.clear
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Prorrogações"
      expect(page.all("tr th").map(&:text)).to eq [
        "Matrícula", "Data de aprovação", "Tipo de prorrogação", "Validade", ""
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
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert and remove record" do
      # Insert record
      expect(page).to have_content "Adicionar Prorrogação"
      fill_record_select("enrollment_", "enrollments", "M04")
      page.send_keys :escape
      within("#as_#{plural_name}-create--form") do
        select_month_year_i("record_approval_date", Date.today)
        find(:select, "record_deferral_type_").find(:option, text: "Regular").select_option
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04 - Dani")

      # Remove inserted record
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M04 - Dani", "M02 - Bia", "M01 - Ana", "M03 - Carol"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia", "M01 - Ana", "M03 - Carol"]
    end

    it "should have a record_select widget for enrollment" do
      expect_to_have_record_select(page, "enrollment_", "enrollments")
    end

    it "should have a month_year widget for approval_date" do
      page.send_keys :escape
      expect_to_have_month_year_widget_i(page, "approval_date", "")
    end

    it "should have a selection for deferral_type options" do
      page.send_keys :escape
      expect(page.all("select#record_deferral_type_ option").map(&:text)).to eq ["Selecione uma opção", "Extraordinária", "Final", "Regular"]
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
        select_month_year_i("record_approval_date", date)
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("#as_#{plural_name}-list-#{@record.id}-row td.approval_date-column", text: I18n.l(date, format: "%B-%Y"))
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by enrollment number" do
      fill_in "search", with: "M02"
      sleep(0.8)
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end
  end
end

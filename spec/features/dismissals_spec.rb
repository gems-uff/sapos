# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dismissal features", type: :feature do
  let(:url_path) { "/dismissals" }
  let(:plural_name) { "dismissals" }
  let(:model) { Dismissal }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)
    @destroy_all << @level = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student2, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)

    @destroy_all << @dismissal_reason1 = FactoryBot.create(:dismissal_reason, name: "Reprovado", thesis_judgement: "Reprovado")
    @destroy_all << @dismissal_reason2 = FactoryBot.create(:dismissal_reason, name: "Titulação", thesis_judgement: "Aprovado")

    @destroy_all << @record = FactoryBot.create(:dismissal, enrollment: @enrollment1, date: Date.today, dismissal_reason: @dismissal_reason1)
    @destroy_all << FactoryBot.create(:dismissal, enrollment: @enrollment2, date: Date.today, dismissal_reason: @dismissal_reason2)
    @destroy_all << FactoryBot.create(:dismissal, enrollment: @enrollment3, date: Date.today, dismissal_reason: @dismissal_reason1)
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
      expect(page).to have_content "Desligamentos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Matrícula", "Motivo do Desligamento", "Data", "Observação", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Ana", "M01 - Bia", "M03 - Carol"]
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
      expect(page).to have_content "Adicionar Desligamento"
      fill_record_select("enrollment_", "enrollments", "M04")
      date = Date.today
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_dismissal_reason_").find(:option, text: @dismissal_reason1.name).select_option
        find(:select, "record_date_2i").find(:option, text: I18n.l(date, format: "%B")).select_option
        find(:select, "record_date_1i").find(:option, text: date.year.to_s).select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04")
      expect(page).to have_css("tr:nth-child(1) td.dismissal_reason-column", text: @dismissal_reason1.name)

      # Remove inserted enrollments
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M04 - Dani", "M02 - Ana", "M01 - Bia", "M03 - Carol"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Ana", "M01 - Bia", "M03 - Carol"]
    end

    it "should have a month_year widget for date" do
      field = "date"
      expect(page.all("select#record_#{field}_2i option").map(&:text)).to eq ["", "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
      expect(page.all("select#record_#{field}_1i option").map(&:text)).to include(1.years.ago.year.to_s, 1.years.since.year.to_s)
    end

    it "should have a record_select widget for enrollment" do
      expect_to_have_record_select(page, "enrollment_", "enrollments")
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit records" do
      within(".as_form") do
        fill_in "Observação", with: "Teste"
      end
      click_button "Atualizar"
      expect(page).to have_css("tr:nth-child(1) td.obs-column", text: "Teste")
    end

    it "should have load the correct dismissal reason" do
      expect(find("#record_dismissal_reason_#{@record.id}").value).to eq @dismissal_reason1.id.to_s
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by enrollment" do
      fill_in "Matrícula", with: "M03"
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol"]
    end
  end
end

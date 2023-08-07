# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Advisements features", type: :feature do
  let(:url_path) { "/advisements" }
  let(:plural_name) { "advisements" }
  let(:model) { Advisement }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @dismissal_reason = FactoryBot.create(:dismissal_reason, name: "Titulação", thesis_judgement: "Aprovado")

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Erica", cpf: "3")
    @destroy_all << @professor2 = FactoryBot.create(:professor, name: "Fiona", cpf: "2")

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student2, level: @level2, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level1, enrollment_status: @enrollment_status)

    @destroy_all << FactoryBot.create(:dismissal, enrollment: @enrollment1, date: Date.today, dismissal_reason: @dismissal_reason)

    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment1, professor: @professor1, main_advisor: true)
    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment2, professor: @professor2, main_advisor: true)
    @destroy_all << @record = FactoryBot.create(:advisement, enrollment: @enrollment3, professor: @professor1, main_advisor: true)
    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment3, professor: @professor2, main_advisor: false)

    @destroy_all << @user = create_confirmed_user(@role_adm)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @role_adm.delete
    @destroy_all.each(&:delete)
    @destroy_all.clear
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Orientações"
      expect(page.all("tr th").map(&:text)).to eq [
        "Orientador", "Matrícula", "Orientador Principal", "Orientação ativa?", "Possui coorientador?", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.professor-column").map(&:text)).to eq ["Erica", "Fiona", "Erica", "Fiona"]
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
      expect(page.all("tr td.active-column").map(&:text)).to eq ["Não", "Sim", "Sim", "Sim"]
      expect(page.all("tr td.co_advisor-column").map(&:text)).to eq ["Não", "Não", "Sim", "Sim"]
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
      expect(page).to have_content "Adicionar Orientação"
      fill_record_select("professor_", "professors", "Fiona")
      fill_record_select("enrollment_", "enrollments", "M04")
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04 - Dani")

      # Remove inserted record
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M04 - Dani", "M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should have a record_select widget for professor" do
      expect_to_have_record_select(page, "professor_", "professors")
    end

    it "should have a record_select widget for enrollment" do
      page.send_keys :escape
      expect_to_have_record_select(page, "enrollment_", "enrollments")
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
        find(:css, "#record_main_advisor_#{@record.id}").set(false)
      end
      click_button "Atualizar"
      expect(page).not_to have_selector("#as_#{plural_name}-list-#{@record.id}-row td.main_advisor-column input:checked:disabled")
      @record.main_advisor = true
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
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M03 - Carol"]
    end

    it "should be able to search by enrollment" do
      page.send_keys :escape
      fill_in "Número de Matrícula", with: "M03"
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol", "M03 - Carol"]
    end

    it "should be able to search by level = Todos" do
      page.send_keys :escape
      find(:select, "search_level").find(:option, text: "Todos").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should be able to search by level = Mestrado" do
      page.send_keys :escape
      find(:select, "search_level").find(:option, text: "Mestrado").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia"]
    end

    it "should be able to search by main_advisor = Sim" do
      page.send_keys :escape
      find(:select, "search_main_advisor").find(:option, text: "Sim").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol"]
    end

    it "should be able to search by main_advisor = Não" do
      page.send_keys :escape
      find(:select, "search_main_advisor").find(:option, text: "Não").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol"]
    end

    it "should be able to search by active = Todas" do
      page.send_keys :escape
      find(:select, "search_active").find(:option, text: "Todas").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should be able to search by active = Ativas" do
      page.send_keys :escape
      find(:select, "search_active").find(:option, text: "Ativas").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should be able to search by active = Inativas" do
      page.send_keys :escape
      find(:select, "search_active").find(:option, text: "Inativas").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana"]
    end

    it "should be able to search by co_advisor = Sim" do
      page.send_keys :escape
      find(:select, "search_co_advisor").find(:option, text: "Sim").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol", "M03 - Carol"]
    end

    it "should be able to search by co_advisor = Não" do
      page.send_keys :escape
      find(:select, "search_co_advisor").find(:option, text: "Não").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia"]
    end
  end

  describe "generate report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download a pdf report of orientations" do
      click_link "Gerar relatório"

      wait_for_download
      expect(download).to match(/Relatório de Orientações\.pdf/)
    end
  end
end

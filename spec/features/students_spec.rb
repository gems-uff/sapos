# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require Rails.root.join "spec/support/user_helpers.rb"

# ToDo: webcam photo widget
# ToDo: majors
# ToDo: edit page of who can only update photo
# ToDo: search
# ToDo: remove

RSpec.describe "Student features", type: :feature do
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador
    @destroy_all << level = FactoryBot.create(:level)
    @destroy_all << enrollment_status = FactoryBot.create(:enrollment_status)

    @destroy_all << FactoryBot.create(:student, name: "Carol", cpf: "3")
    @destroy_all << @student = FactoryBot.create(:student, name: "Bia", cpf: "2")
    @destroy_all << FactoryBot.create(:student, name: "Dani", cpf: "4")
    @destroy_all << FactoryBot.create(:enrollment, enrollment_number: "M001", student: @student, level: level, enrollment_status: enrollment_status)
    @destroy_all << @user = create_confirmed_user(@role_adm)
    prepare_city_widget(@destroy_all)
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
      visit "/students"
    end

    it "should show students table" do
      expect(page).to have_content "Alunos"
      expect(page).to have_content "Nome"
      expect(page).to have_content "CPF"
      expect(page).to have_content "Matrículas"
    end

    it "should sort the list by name, asc" do
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Bia")
      expect(page).to have_css("tr:nth-child(2) td.name-column", text: "Carol")
      expect(page).to have_css("tr:nth-child(3) td.name-column", text: "Dani")
    end

    it "should show the enrollment number" do
      expect(page).to have_css("tr:nth-child(1) td.enrollments-column", text: "M001")
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit "/students"
      click_link "Adicionar"
    end

    it "should be able to insert student" do
      expect(page).to have_content "Adicionar Aluno"
      within("#as_students-create--form") do
        fill_in "Nome", with: "Ana"
        fill_in "CPF", with: "1"
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Ana")
      expect(Student.last.photo.file).to eq nil
    end

    it "should be able to upload image" do
      expect(page).to have_content "Adicionar Aluno"
      within("#as_students-create--form") do
        fill_in "Nome", with: "Erica"
        fill_in "CPF", with: "5"
        attach_file("Foto", Rails.root + "spec/fixtures/user.png")
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Erica")
      expect(Student.last.photo.file).not_to eq nil
    end


    it "should have city widget for birth_city" do
      expect_to_have_city_widget(page, "birth_city_", "birth_state_", "birth_country_")
    end

    it "should have city widget for address" do
      expect_to_have_city_widget(page, "city_", "address_state_", "address_country_")
    end

    it "should have a selection for sex options" do
      expect(page.all("select#record_sex_ option").map(&:text)).to eq ["Masculino", "Feminino"]
      expect(page.all("select#record_sex_ option").map(&:value)).to eq ["M", "F"]
    end

    it "should have a selection for civil_status options" do
      expect(page.all("select#record_civil_status_ option").map(&:text)).to eq ["Solteiro(a)", "Casado(a)"]
      expect(page.all("select#record_civil_status_ option").map(&:value)).to eq ["Solteiro(a)", "Casado(a)"]
    end

    it "should have identity issuing place widget for identity issuing place" do
      expect_to_have_identity_issuing_place_widget(page, "identity_issuing_place")
    end

    it "should have a datepicker for birthdate with a range starting 100 years ago" do
      expect(page).not_to have_selector("#ui-datepicker-div")
      find("#record_birthdate_").click
      expect(page).to have_selector("#ui-datepicker-div", visible: true)
      expect(page.all("select.ui-datepicker-year option").map(&:text)).to include(100.years.ago.year.to_s)
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      @state = State.first
      @city = City.first
      @student.city = @city
      @student.birth_city = @city
      @student.identity_issuing_place = @state.name
      @student.birthdate = 25.years.ago
      @student.save!
      visit "/students"
      find("#as_students-edit-#{@student.id}-link").click
    end

    it "should be able to edit student" do
      within(".as_form") do
        fill_in "Nome", with: "teste"
        fill_in "CPF", with: "9"
      end
      click_button "Atualizar"
      expect(page).to have_css("td.name-column", text: "teste")
      expect(page).to have_css("td.cpf-column", text: "9")
    end

    it "should load the original city widget values" do
      expect(find("#widget_record_birth_city_#{@student.id}").value).to eq @city.id.to_s
      expect(find("#widget_record_birth_state_#{@student.id}").value).to eq @city.state.id.to_s
      expect(find("#widget_record_birth_country_#{@student.id}").value).to eq @city.state.country.id.to_s
    end

    it "should have city widget for address" do
      expect(find("#widget_record_city_#{@student.id}").value).to eq @city.id.to_s
      expect(find("#widget_record_address_state_#{@student.id}").value).to eq @city.state.id.to_s
      expect(find("#widget_record_address_country_#{@student.id}").value).to eq @city.state.country.id.to_s
    end

    it "should have identity issuing place widget for identity issuing place" do
      expect(find("#widget_record_identity_issuing_place_select_#{@student.id}").value).to eq @state.name
    end

    it "should have a datepicker for birthdate with a range starting 100 years ago" do
      expect(find("#record_birthdate_#{@student.id}").value).to eq 25.years.ago.strftime("%d/%m/%Y")
    end
  end
end

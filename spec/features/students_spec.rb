# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: webcam photo widget
# ToDo: majors
# ToDo: edit page of who can only update photo

RSpec.describe "Student features", type: :feature do
  let(:url_path) { "/students" }
  let(:plural_name) { "students" }
  let(:model) { Student }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador
    prepare_city_widget(@destroy_all)
    @state = State.first
    @city = City.first
    @destroy_all << level = FactoryBot.create(:level)
    @destroy_all << enrollment_status = FactoryBot.create(:enrollment_status)
    @destroy_all << FactoryBot.create(:student, name: "Carol", cpf: "3")
    @destroy_all << @record = FactoryBot.create(
      :student, name: "Bia", cpf: "2",
      city: @city, birth_city: @city, birth_state: @city.state, birth_country: @city.state.country,
      identity_issuing_place: @state.name, birthdate: 25.years.ago
    )
    @destroy_all << FactoryBot.create(:student, name: "Dani", cpf: "4")
    @destroy_all << FactoryBot.create(:enrollment, enrollment_number: "M001", student: @record, level: level, enrollment_status: enrollment_status)
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
      expect(page).to have_content "Alunos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "CPF", "Matrículas", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Bia", "Carol", "Dani"]
    end

    it "should show the enrollment number" do
      expect(page).to have_css("tr:nth-child(1) td.enrollments-column", text: "M001")
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
      expect(page).to have_content "Adicionar Aluno"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Ana"
        fill_in "CPF", with: "1"
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Ana")
      expect(Student.last.photo.file).to eq nil

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Ana", "Bia", "Carol", "Dani"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Bia", "Carol", "Dani"]
    end

    it "should be able to upload image" do
      expect(page).to have_content "Adicionar Aluno"
      within("#as_#{plural_name}-create--form") do
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
      expect(page.all("select#record_sex_ option").map(&:text)).to eq ["Não declarado", "Masculino", "Feminino"]
    end

    it "should have a selection for pcd options" do
      expect(page.all("select#record_pcd_ option").map(&:text)).to eq I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiencies").values
      expect(page.all("select#record_pcd_ option").map(&:value)).to eq I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiencies").values
    end

    it "should have a textarea for obs pcd" do
      expect(page).to have_field("Observações de PCD", type: "textarea")
    end

    it "should have a selection for humanity policy options" do
      expect(page.all("select#record_humanitarian_policy_ option").map(&:text)).to eq ["Não declarado", "Não se aplica", "Refugiado", "Solicitante de refúgio", "Asilado político", "Apátrida", "Portador de autorização de residência por motivo de acolhida humanitária", "Portador de autorização de residência sob os quais recaem outras políticas humanitárias no Brasil"]
      expect(page.all("select#record_humanitarian_policy_ option").map(&:value)).to eq ["Não declarado", "Não se aplica", "Refugiado", "Solicitante de refúgio", "Asilado político", "Apátrida", "Portador de autorização de residência por motivo de acolhida humanitária", "Portador de autorização de residência sob os quais recaem outras políticas humanitárias no Brasil"]
    end
    it "should have a textarea for obs" do
      expect(page).to have_field("Observações", type: "textarea")
    end

    it "should have a selection for skin_color options" do
      expect(page.all("select#record_skin_color_ option").map(&:text)).to eq I18n.t("active_scaffold.admissions/form_template.generate_fields.skin_colors").values
      expect(page.all("select#record_skin_color_ option").map(&:value)).to eq I18n.t("active_scaffold.admissions/form_template.generate_fields.skin_colors").values
    end

    it "should have a selection for gender options" do
      expect(page.all("select#record_gender_ option").map(&:text)).to eq I18n.t("active_scaffold.admissions/form_template.generate_fields.genders").values
      expect(page.all("select#record_gender_ option").map(&:value)).to eq I18n.t("active_scaffold.admissions/form_template.generate_fields.genders").values
    end

    it "should have a selection for civil_status options" do
      expect(page.all("select#record_civil_status_ option").map(&:text)).to eq ["Não declarado", "Solteiro(a)", "Casado(a)"]
      expect(page.all("select#record_civil_status_ option").map(&:value)).to eq ["Não declarado", "Solteiro(a)", "Casado(a)"]
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
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit record" do
      within(".as_form") do
        fill_in "Nome", with: "teste"
        fill_in "CPF", with: "9"
      end
      click_button "Atualizar"
      expect(page).to have_css("td.name-column", text: "teste")
      expect(page).to have_css("td.cpf-column", text: "9")
    end

    it "should load the original city widget values" do
      expect(find("#widget_record_birth_city_#{@record.id}").value).to eq @city.id.to_s
      expect(find("#widget_record_birth_state_#{@record.id}").value).to eq @city.state.id.to_s
      expect(find("#widget_record_birth_country_#{@record.id}").value).to eq @city.state.country.id.to_s
    end

    it "should have city widget for address" do
      expect(find("#widget_record_city_#{@record.id}").value).to eq @city.id.to_s
      expect(find("#widget_record_address_state_#{@record.id}").value).to eq @city.state.id.to_s
      expect(find("#widget_record_address_country_#{@record.id}").value).to eq @city.state.country.id.to_s
    end

    it "should have identity issuing place widget for identity issuing place" do
      expect(find("#record_identity_issuing_place_#{@record.id}").value).to eq @state.name
    end

    it "should have a datepicker for birthdate with a range starting 100 years ago" do
      expect(find("#record_birthdate_#{@record.id}").value).to eq 25.years.ago.strftime("%d/%m/%Y")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Bia"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Bia"]
    end
  end
end

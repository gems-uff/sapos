# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: advisement_points (table and show)
# ToDo: professor research area

RSpec.describe "Professors features", type: :feature do
  let(:url_path) { "/professors" }
  let(:plural_name) { "professors" }
  let(:model) { Professor }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador
    prepare_city_widget(@destroy_all)
    @state = State.first
    @city = City.first
    @destroy_all << @level1 = FactoryBot.create(:level, name: "Mestrado", show_advisements_points_in_list: true,
     short_name_showed_in_list_header: "M", default_duration: 24)
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Doutorado", show_advisements_points_in_list: true,
     short_name_showed_in_list_header: "D", default_duration: 48)
    @destroy_all << @level3 = FactoryBot.create(:level, name: "Especialização", show_advisements_points_in_list: false,
     short_name_showed_in_list_header: "E",  default_duration: 0)

    config = CustomVariable.find_by_variable(:single_advisor_points)
    config.delete unless config.nil?
    config = CustomVariable.find_by_variable(:multiple_advisor_points)
    config.delete unless config.nil?
    @destroy_later << CustomVariable.create(variable: :single_advisor_points, value: "1.0")
    @destroy_later << CustomVariable.create(variable: :multiple_advisor_points, value: "0.5")

    @destroy_later << enrollment1 = FactoryBot.create(:enrollment, level: @level1)
    @destroy_later << enrollment2 = FactoryBot.create(:enrollment, level: @level2)
    @destroy_later << enrollment3 = FactoryBot.create(:enrollment, level: @level1)
    @destroy_later << enrollment4 = FactoryBot.create(:enrollment, level: @level2)


    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Carol", cpf: "3")
    @destroy_all << @professor2 = FactoryBot.create(
      :professor, name: "Bia", cpf: "2",
      city: @city, identity_issuing_place: @state.name, birthdate: 25.years.ago
    )
    @destroy_all << @professor3 = FactoryBot.create(:professor, name: "Dani", cpf: "4")

    @destroy_later << FactoryBot.create(:advisement_authorization, professor: @professor1, level: @level1)
    @destroy_later << FactoryBot.create(:advisement_authorization, professor: @professor2, level: @level1)
    @destroy_later << FactoryBot.create(:advisement_authorization, professor: @professor2, level: @level2)


    @destroy_later << FactoryBot.create(:advisement, professor: @professor1, enrollment: enrollment1, main_advisor: true)
    @destroy_later << FactoryBot.create(:advisement, professor: @professor1, enrollment: enrollment3)
    @destroy_later << FactoryBot.create(:advisement, professor: @professor2, enrollment: enrollment1, main_advisor: false)
    @destroy_later << FactoryBot.create(:advisement, professor: @professor2, enrollment: enrollment2, main_advisor: true)
    @destroy_later << FactoryBot.create(:advisement, professor: @professor2, enrollment: enrollment4)
    @destroy_later << FactoryBot.create(:advisement, professor: @professor3, enrollment: enrollment1, main_advisor: false)
    @destroy_later << FactoryBot.create(:advisement, professor: @professor3, enrollment: enrollment2, main_advisor: false)

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
      expect(page).to have_content "Professores"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "CPF", "Data de Nascimento", "Pontos Total", "D", "M", "Matrícula", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Bia", "Carol", "Dani"]
    end
  end

  describe "sort by partial points", js: true, order: :defined do
    before(:each) do
      login_as(@user)
      visit url_path
    end
    it "Should sort the list by the points of a level, asc, if clicked on its column first time" do
      click_on "M"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Dani", "Bia", "Carol"]
      expect(page.all("tr td.advisement_points_of_level1-column").map(&:text)).to eq ["0.0", "0.5", "1.5"]
    end

    it "Should sort the list by the points of a level, desc, if clicked on its column second time" do
      2.times do
        click_on "M"
      end
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Carol", "Bia", "Dani"]
      expect(page.all("tr td.advisement_points_of_level1-column").map(&:text)).to eq ["1.5", "0.5", "0.0"]
    end

    it "Should back to default sort, if clicked on its column third time" do
      3.times do
        click_on "M"
      end
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Bia", "Carol", "Dani"]
      expect(page.all("tr td.advisement_points_of_level1-column").map(&:text)).to eq ["0.5", "1.5", "0.0"]
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
      expect(page).to have_content "Adicionar Professor"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Ana"
        fill_in "CPF", with: "1"
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Ana")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Ana", "Bia", "Carol", "Dani"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Bia", "Carol", "Dani"]
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
      expect(page.all("select#record_civil_status_ option").map(&:value)).to eq ["solteiro", "casado"]
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

    it "should have a selection for academic_title_level options" do
      expect(page.all("select#record_academic_title_level_ option").map(&:text)).to eq ["Selecione uma opção", "Doutorado", "Especialização", "Mestrado"]
      expect(page.all("select#record_academic_title_level_ option").map(&:value)).to eq ["", @level2.id.to_s, @level3.id.to_s, @level1.id.to_s]
    end

    it "should have a selection for academic_title_country options" do
      expect(page.all("select#record_academic_title_country_ option").map(&:text)).to eq ["Selecione uma opção", "Brasil", "USA"]
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@professor2.id}-link").click
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

    it "should have city widget for address" do
      expect(find("#widget_record_city_#{@professor2.id}").value).to eq @city.id.to_s
      expect(find("#widget_record_address_state_#{@professor2.id}").value).to eq @city.state.id.to_s
      expect(find("#widget_record_address_country_#{@professor2.id}").value).to eq @city.state.country.id.to_s
    end

    it "should have identity issuing place widget for identity issuing place" do
      expect(find("#record_identity_issuing_place_#{@professor2.id}").value).to eq @state.name
    end

    it "should have a datepicker for birthdate with a range starting 100 years ago" do
      expect(find("#record_birthdate_#{@professor2.id}").value).to eq 25.years.ago.strftime("%d/%m/%Y")
    end
  end

  describe "edit as secretaria", js: true do
    before(:each) do
      @destroy_all << @role_sec = FactoryBot.create(:role_secretaria)
      @destroy_all << @user_sec = create_confirmed_user(@role_sec, email: "secretaria@secretaria.com")
      login_as(@user_sec)
      visit url_path
      find("#as_#{plural_name}-edit-#{@professor2.id}-link").click
    end

    it "should have a nested affiliation" do
      expect(page).to have_field(class: "institution-input")
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

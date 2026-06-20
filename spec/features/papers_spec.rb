# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Papers features", type: :feature do
  let(:url_path) { "/papers" }
  let(:plural_name) { "papers" }
  let(:model) { Paper }

  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Ana", cpf: "1")
    @destroy_all << @professor2 = FactoryBot.create(:professor, name: "Bia", cpf: "2")
    @destroy_all << @professor3 = FactoryBot.create(:professor, name: "Carlos", cpf: "3")

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Discente1", cpf: "d1")

    @destroy_all << @record = FactoryBot.create(:paper,
      period: "2021 - 2024",
      reference: "Autor1. Artigo Alpha. 2022",
      kind: Paper::JOURNAL,
      doi_issn_event: "10.1000/alpha",
      owner: @professor1,
      reason_justify: "Relevante internacionalmente",
      order: 1
    )
    @destroy_all << FactoryBot.create(:paper,
      period: "2021 - 2024",
      reference: "Autor2. Artigo Beta. 2023",
      kind: Paper::CONFERENCE,
      doi_issn_event: "CONF-BETA",
      owner: @professor2,
      reason_justify: "Relevante nacionalmente",
      order: 1
    )

    @destroy_all << @user = create_confirmed_user([@role_adm])
  end

  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  after(:all) do
    @role_adm.delete
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
      expect(page).to have_content "Artigo"
      expect(page.all("tr th").map(&:text)).to eq [
        "Avaliação quadrienal - 4N", "Professor", "Relevância", "Referência completa", ""
      ]
    end

    it "should sort the list by period desc, then owner asc" do
      expect(page.all("tr td.reference-column").map(&:text)).to eq [
        "Autor1. Artigo Alpha. 2022",
        "Autor2. Artigo Beta. 2023"
      ]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert record" do
      expect(page).to have_content "Adicionar Artigo"

      # Campos principais
      within("#as_#{plural_name}-create--form") do
        fill_in "Avaliação quadrienal - 4N", with: "2021 - 2024"
        fill_in "Referência completa", with: "Autor. Artigo Completo. 2024"
        fill_in "DOI ou ISSN ou Sigla Evento", with: "10.1234/completo"
        fill_in "Outros autores separados por ';'", with: "Coautor Externo; Outro Coautor"
        find(:select, "record_kind_").find(:option, text: Paper::CONFERENCE).select_option
        find(:select, "record_order_").find(:option, text: "3").select_option
      end
      fill_record_select("owner_", "professors", "Carlos")

      # Campos de motivo (checkboxes booleanos)
      within("#as_#{plural_name}-create--form") do
        find("#record_reason_impact_factor_").check
        find("#record_reason_international_list_").check
        find("#record_reason_citations_").check
        find("#record_reason_national_interest_").check
        find("#record_reason_international_interest_").check
        find("#record_reason_national_representativeness_").check
        find("#record_reason_scientific_contribution_").check
        find("#record_reason_tech_contribution_").check
        find("#record_reason_innovation_contribution_").check
        find("#record_reason_social_contribution_").check
        fill_in "record_reason_other_", with: "Outro aspecto relevante"
        fill_in "record_reason_justify_",
          with: "Justificativa detalhada de todos os aspectos marcados"
        fill_in "record_other_", with: "Observação adicional sobre o artigo"
      end

      click_button_and_wait "Salvar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_content("Autor. Artigo Completo. 2024")

      @destroy_later << model.last
    end

    it "should have a select for kind options" do
      expect(page.all("select#record_kind_ option").map(&:text)).to include(
        Paper::JOURNAL, Paper::CONFERENCE
      )
    end

    it "should have a select for order options" do
      options = page.all("select#record_order_ option").map(&:text)
      expect(options).to include("1", "2", "3", "4", "5", "6", "7", "8")
    end

    it "should have a link to add paper_professors" do
      expect(page).to have_link("as_papers-99999999999-paper_professors-subform-div-create-another")
    end

    it "should have a link to add paper_students" do
      expect(page).to have_link("as_papers-99999999999-paper_students-subform-div-create-another")
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
        fill_in "Referência completa", with: "Autor1. Artigo Alpha Atualizado. 2022"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css(
        "#as_#{plural_name}-list-#{@record.id}-row td.reference-column",
        text: "Autor1. Artigo Alpha Atualizado. 2022"
      )
    end
  end
end

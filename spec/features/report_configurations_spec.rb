# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ReportConfigurations features", type: :feature do
  let(:url_path) { "/report_configurations" }
  let(:plural_name) { "report_configurations" }
  let(:model) { ReportConfiguration }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << FactoryBot.create(:report_configuration, name: "Padrão", scale: 1, x: 0, y: 0, order: 1, text: "UFF")
    @destroy_all << @record = FactoryBot.create(:report_configuration, name: "Histórico", scale: 1, x: 0, y: 0, order: 1, text: "UFF", image: File.open(Rails.root + "spec/fixtures/user.png"))
    @destroy_all << @record2 = FactoryBot.create(:report_configuration, name: "Boletim", scale: 1, x: 0, y: 0, order: 1, text: "UFF")
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
      expect(page).to have_content "Configurações de relatório"
      expect(page.all("tr th").map(&:text)).to eq [
                                                    "Nome", "Prioridade", "Header", "Tipo de Assinatura", "Usar em relatórios", "Usar no histórico", "Usar no boletim", "Usar no quadro de horários", "Usar em declarações", "Validade (meses)", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq %w[Boletim Histórico Padrão]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Adicionar"
    end

    it "should be able to insert record with uploaded logo, preview it and remove record" do
      # Insert record
      expect(page).to have_content "Adicionar Configuração de Relatório"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Relatório"
        fill_in "Escala", with: "1"
        fill_in "X", with: "0"
        fill_in "Y", with: "0"
        fill_in "Prioridade", with: "1"
        fill_in "Header", with: "UFF"
        attach_file("Logo", Rails.root + "spec/fixtures/user.png")
      end
      # Preview
      click_link "Visualizar"

      wait_for_download
      expect(download).to match(/Visualizar\.pdf/)

      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Relatório")
      expect(model.last.image.file).not_to eq nil

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Relatório", "Boletim", "Histórico", "Padrão"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Boletim", "Histórico", "Padrão"]
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
        fill_in "Nome", with: "Quadro de Horários"
      end
      click_button "Atualizar"
      expect(page).to have_css("td.name-column", text: "Quadro de Horários")
    end
  end

  describe "duplicate link", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should be able to duplicate record with logo" do
      expect(page.all("tr td.name-column").size).to eq 3
      find("#as_#{plural_name}-duplicate-#{@record.id}-link").click
      expect(page.all("tr td.name-column").size).to eq 4
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").size).to eq 3
    end

    it "should be able to duplicate record without logo" do
      expect(page.all("tr td.name-column").size).to eq 3
      find("#as_#{plural_name}-duplicate-#{@record2.id}-link").click
      expect(page.all("tr td.name-column").size).to eq 4
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").size).to eq 3
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Bol"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Boletim"]
    end
  end
end

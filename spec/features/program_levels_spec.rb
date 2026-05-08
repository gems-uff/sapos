# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ProgramLevels features", type: :feature do
  let(:url_path) { "/program_levels" }
  let(:plural_name) { "program_levels" }
  let(:model) { ProgramLevel }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador

    @destroy_all << @record = FactoryBot.create(:program_level,
      level: 5,
      ordinance: "Portaria MEC 1234/2020",
      start_date: Date.new(2020, 1, 1),
      end_date: nil
    )
    @destroy_all << FactoryBot.create(:program_level,
      level: 4,
      ordinance: "Portaria MEC 5678/2015",
      start_date: Date.new(2015, 1, 1),
      end_date: Date.new(2019, 12, 31)
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
      expect(page).to have_content "Conceito CAPES"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nível", "Portaria", "Data de início", "Data de fim", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.level-column").map(&:text)).to eq ["5", "4"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert and remove record" do
      expect(page).to have_content "Create Model"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nível", with: "6"
        fill_in "Portaria", with: "Portaria MEC 9999/2024"
        fill_in "Data de início", with: Date.today.strftime("%d/%m/%Y")
      end
      click_button_and_wait "Salvar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("tr:nth-child(1) td.level-column", text: "6")

      expect(page.all("tr td.level-column").map(&:text).count).to eq 3
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      expect(page).to have_no_css("tr:nth-child(1) td.level-column", text: "6")
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
        fill_in "Portaria", with: "Portaria MEC Atualizada"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css(
        "#as_#{plural_name}-list-#{@record.id}-row td.ordinance-column",
        text: "Portaria MEC Atualizada"
      )
    end
  end
end

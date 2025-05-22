# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# ToDo: fix search to look for content

require "spec_helper"

RSpec.describe "Versions features", type: :feature do
  let(:url_path) { "/versions" }
  let(:plural_name) { "versions" }
  let(:model) { Version }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])
    @destroy_all << @country1 = FactoryBot.create(:country, name: "Brasil", nationality: "brasileiro(a)")
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
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
      expect(page).to have_content "Log"
      expect(page.all("tr th").map(&:text)).to eq [
        "Modelo", "Versão Atual", "Ação", "Usuário", "Modificado em", ""
      ]
    end

    it "should sort the list by created_at, desc" do
      # First item is the user login
      expect(page.all("tr:nth-child(1) td.item_type-column").map(&:text)).to eq ["Usuário"]
      # Second item is the country
      expect(page.all("tr:nth-child(2) td.item_type-column").map(&:text)).to eq ["País"]
    end

    it "should not have insert link" do
      expect(page).not_to have_content "Adicionar"
    end

    it "should not have edit link" do
      expect(page).not_to have_selector("#as_#{plural_name}-edit-#{model.last.id}-link")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by model name" do
      fill_in "search", with: "Country"
      sleep(0.8)
      expect(page.all("tr td.item_type-column").map(&:text)).to include("País")
    end
  end
end

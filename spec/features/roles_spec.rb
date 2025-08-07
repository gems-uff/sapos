# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# ToDo: fix search to look for content

require "spec_helper"

RSpec.describe "Roles features", type: :feature do
  let(:url_path) { "/roles" }
  let(:plural_name) { "role" }
  let(:model) { Role }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << FactoryBot.create(:role_desconhecido)
    @destroy_all << FactoryBot.create(:role_coordenacao)
    @destroy_all << FactoryBot.create(:role_secretaria)
    @destroy_all << FactoryBot.create(:role_professor)
    @destroy_all << FactoryBot.create(:role_aluno)
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << FactoryBot.create(:role_suporte)
    @destroy_all << @user = create_confirmed_user(@role_adm)
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
      expect(page).to have_content "Papéis"
      expect(page.all("tr th").map(&:text)).to eq [
        "Id", "Nome", "Descrição", ""
      ]
    end

    it "should sort the list by created_at, desc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Desconhecido", "Coordenação", "Secretaria", "Professor", "Aluno", "Administrador", "Suporte"]
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
      click_link_and_wait "Buscar"
    end

    it "should be able to search by model name" do
      fill_in "search", with: "Coor"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Coordenação"]
    end
  end
end

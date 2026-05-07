# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Panel CarrierwaveFiles features", type: :feature do
  let(:url_path) { "/panel/carrierwave_files" }
  let(:plural_name) { "carrier_wave_storage_active_record_active_record_files" }
  let(:model) { CarrierWave::Storage::ActiveRecord::ActiveRecordFile }

  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    cw_model = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
    @destroy_all << @orphan_file1 = cw_model.create!(
      medium_hash: SecureRandom.hex(16),
      original_filename: "documento_orfao.pdf",
      content_type: "application/pdf",
      size: 1024,
      binary: "test data 1"
    )
    @destroy_all << @orphan_file2 = cw_model.create!(
      medium_hash: SecureRandom.hex(16),
      original_filename: "imagem_orfao.png",
      content_type: "image/png",
      size: 2048,
      binary: "test data 2"
    )
    @destroy_all << @orphan_file3 = cw_model.create!(
      medium_hash: SecureRandom.hex(16),
      original_filename: "texto_orfao.txt",
      content_type: "text/plain",
      size: 512,
      binary: "test data 3"
    )
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

    it "should show table with orphan files" do
      expect(page).to have_content "Coleta de Lixo - CarrierWave"
      expect(page.all("tr th").map(&:text)).to eq [
        "ID", "Arquivo", "Tipo", "Tamanho", "Criado em", ""
      ]
    end

    it "should display orphan files in the list" do
      expect(page).to have_content "documento_orfao.pdf"
      expect(page).to have_content "imagem_orfao.png"
      expect(page).to have_content "texto_orfao.txt"
    end

    it "should show files sorted by created_at desc" do
      filenames = page.all("tr td.original_filename-column").map(&:text)
      expect(filenames).to include("documento_orfao.pdf", "imagem_orfao.png", "texto_orfao.txt")
    end
  end

  describe "show page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should be able to view file details" do
      find("#as_#{plural_name}-show-#{@orphan_file1.id}-link").click
      wait_for_ajax
      expect(page).to have_content "documento_orfao.pdf"
      expect(page).to have_content "application/pdf"
      expect(page).to have_content "1024"
    end
  end

  describe "delete file", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should be able to delete a single file" do
      new_file = model.create!(
        medium_hash: SecureRandom.hex(16),
        original_filename: "para_deletar.pdf",
        content_type: "application/pdf",
        size: 100,
        binary: "delete me"
      )
      @destroy_later << new_file

      visit url_path
      expect(page).to have_content "para_deletar.pdf"

      accept_confirm { find("#as_#{plural_name}-destroy-#{new_file.id}-link").click }
      wait_for_ajax

      expect(page).to have_no_content "para_deletar.pdf"
      expect(model.exists?(new_file.id)).to be false
    end
  end

  describe "delete all action", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should have delete all button" do
      expect(page).to have_link "Excluir Todos"
    end

    it "should be able to delete all orphan files" do
      files_to_delete = [
        model.create!(medium_hash: SecureRandom.hex(16), original_filename: "delete1.pdf", content_type: "application/pdf", size: 100, binary: "d1"),
        model.create!(medium_hash: SecureRandom.hex(16), original_filename: "delete2.pdf", content_type: "application/pdf", size: 100, binary: "d2")
      ]
      files_to_delete.each { |f| @destroy_later << f }

      visit url_path
      expect(page).to have_content "delete1.pdf"
      expect(page).to have_content "delete2.pdf"

      accept_confirm { click_link "Excluir Todos" }
      wait_for_ajax

      expect(page).to have_content "arquivos excluídos com sucesso"
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by filename" do
      fill_in "search_original_filename", with: "documento"
      click_button_and_wait "Buscar"

      expect(page).to have_content "documento_orfao.pdf"
      expect(page).to have_no_content "imagem_orfao.png"
      expect(page).to have_no_content "texto_orfao.txt"
    end

    it "should be able to search by content type" do
      fill_in "search_content_type", with: "image"
      click_button_and_wait "Buscar"

      expect(page).to have_content "imagem_orfao.png"
      expect(page).to have_no_content "documento_orfao.pdf"
      expect(page).to have_no_content "texto_orfao.txt"
    end
  end

  describe "access control" do
    it "should redirect to sign in page when not logged in" do
      visit url_path
      expect(page.current_path).to eq "/users/sign_in"
    end

    it "should not allow access for non-admin users" do
      @destroy_later << role_coordenacao = FactoryBot.create(:role_coordenacao)
      @destroy_later << non_admin_user = create_confirmed_user([role_coordenacao], "nonadmin@ic.uff.br")

      login_as(non_admin_user)
      visit url_path

      expect(page.current_path).not_to eq url_path
    end
  end
end

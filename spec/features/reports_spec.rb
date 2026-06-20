# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Reports features", type: :feature do
  let(:url_path) { "/reports" }
  let(:plural_name) { "reports" }
  let(:model) { Report }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])
    @destroy_all << @user2 = create_confirmed_user([@role_adm], "user2@test.com", "User2")

    @destroy_all << @carrierwave_file1 = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.create!(
      original_filename: "documento1.pdf",
      content_type: "application/pdf",
      binary: "test content",
      medium_hash: SecureRandom.hex(16)
    )

    @destroy_all << @carrierwave_file2 = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.create!(
      original_filename: "documento2.pdf",
      content_type: "application/pdf",
      binary: "test content",
      medium_hash: SecureRandom.hex(16)
    )

    @destroy_all << @report1 = FactoryBot.create(:report, user: @user, file_name: "documento1.pdf", carrierwave_file: @carrierwave_file1, created_at: 2.days.ago)
    @destroy_all << @report2 = FactoryBot.create(:report, user: @user2, file_name: "documento2.pdf", carrierwave_file: @carrierwave_file2, created_at: 1.day.ago)
    @destroy_all << @record = FactoryBot.create(:report, user: @user, file_name: "documento_sem_arquivo.pdf", created_at: 3.days.ago)
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
      expect(page).to have_content "Documentos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Gerado por", "Nome do Arquivo", "Identificador", "Data de Criação", "Data de Expiração", ""
      ]
    end

    it "should sort the list by created_at desc" do
      expect(page.all("tr td.file_name-column").map(&:text)).to eq [
        "documento2.pdf", "documento1.pdf", "documento_sem_arquivo.pdf"
      ]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert a report" do
      expect(page).to have_content "Gerar Documento Assinado"
      within("#as_#{plural_name}-create--form") do
        fill_in "Arquivo", with: "novo_documento.pdf"
        fill_in "Título", with: "DECLARAÇÃO DE TESTE"
        fill_in "Corpo do Documento", with: "Este é o corpo do documento de teste."
        fill_in "Validade (meses)", with: "12"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("tr:nth-child(1) td.file_name-column", text: "novo_documento.pdf")

      record = model.last
      @destroy_later << record
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit expires_at" do
      new_date = 2.years.from_now.to_date
      within(".as_form") do
        fill_in "Data de Expiração", with: new_date.strftime("%d/%m/%Y")
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("td.expires_at_or_invalid-column", text: new_date.strftime("%d/%m/%Y"))
    end
  end

  describe "show page" do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-show-#{@record.id}-link").click
    end

    it "should display report details" do
      expect(page).to have_content @record.file_name
      expect(page).to have_content @record.user.name
    end
  end

  describe "download and invalidate actions", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should not have download link for report without file" do
      expect(page).to have_no_selector("#as_#{plural_name}-download-#{@record.id}-link")
    end

    it "should not have invalidate link for report without file" do
      expect(page).to have_no_selector("#as_#{plural_name}-invalidate-#{@record.id}-link")
    end
  end

  describe "invalidate button", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show invalidate link for report with file" do
      expect(page).to have_selector("#as_#{plural_name}-invalidate-#{@report1.id}-link")
    end

    it "should invalidate document when clicking invalidate button and confirming" do
      accept_confirm do
        find("#as_#{plural_name}-invalidate-#{@report1.id}-link").click
      end
      expect(page).to have_content("Documento invalidado com sucesso")
      expect(@report1.reload.invalidated_at).to be_present
      expect(@report1.invalidated_by).to eq(@user)
      expect(@report1.carrierwave_file_id).to be_nil
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by file_name" do
      fill_in "search", with: "documento1"
      expect(page).to have_no_content("documento2.pdf")
      expect(page.all("tr td.file_name-column").map(&:text)).to eq ["documento1.pdf"]
    end
  end

  describe "download report as pdf", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should have download link for report with file" do
      link = find("#as_#{plural_name}-download-#{@report2.id}-link")
      expect(link[:href]).to include("/reports/#{@report2.id}/download")
    end
  end
end

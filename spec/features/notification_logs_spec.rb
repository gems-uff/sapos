# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "NotificationLogs features", type: :feature do
  let(:url_path) { "/notification_logs" }
  let(:plural_name) { "notification_logs" }
  let(:model) { NotificationLog }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << @query1 = FactoryBot.create(:query, name: "students", sql: "select * from students")
    @destroy_all << @query2 = FactoryBot.create(:query, name: "queries", sql: "select name, sql from queries")

    @destroy_all << @notification1 = FactoryBot.create(:notification, query: @query1, title: "saudacao", to_template: "jpimentel@ic.uff.br", subject_template: "Olá", body_template: "Corpo")
    @destroy_all << @notification2 = FactoryBot.create(:notification, query: @query2, title: "despedida", to_template: "jpimentel@ic.uff.br", subject_template: "Tchau", body_template: "<%= var('name') %>")

    @destroy_all << FactoryBot.create(:notification_log, notification: @notification2, to: "jpimentel@ic.uff.br", subject: "Tchau", body: "students")
    @destroy_all << FactoryBot.create(:notification_log, notification: @notification2, to: "jpimentel@ic.uff.br", subject: "Tchau", body: "queries")
    @destroy_all << FactoryBot.create(:notification_log, to: "jpimentel@ic.uff.br", subject: "Sync", body: "Notificação síncrona")
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
      expect(page).to have_content "Notificações Enviadas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Notificação", "Para", "Assunto", "Corpo", "Data de Execução", ""
      ]
    end

    it "should sort the list by created_at, desc" do
      # First item
      expect(page.all("tr:nth-child(1) td.subject-column").map(&:text)).to eq ["Sync"]
      expect(page.all("tr:nth-child(1) td.notification_name-column").map(&:text)).to eq ["Notificação Síncrona ou Assíncrona Removida"]
      # Second item
      expect(page.all("tr:nth-child(2) td.subject-column").map(&:text)).to eq ["Tchau"]
      expect(page.all("tr:nth-child(2) td.notification_name-column").map(&:text)).to eq ["despedida"]
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

    it "should be able to search by subject" do
      fill_in "search", with: "syn"
      sleep(0.8)
      expect(page.all("tr td.subject-column").map(&:text)).to include("Sync")
    end
  end
end

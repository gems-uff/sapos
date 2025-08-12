# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EmailTemplates features", type: :feature do
  let(:url_path) { "/email_templates" }
  let(:plural_name) { "email_templates" }
  let(:model) { EmailTemplate }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << FactoryBot.create(:email_template, name: "saudacao", to: "jpimentel@ic.uff.br", subject: "Olá", body: "Corpo")
    @destroy_all << @record = FactoryBot.create(:email_template, name: "despedida", to: "jpimentel@ic.uff.br", subject: "Tchau", body: "Corpo")
    @destroy_all << FactoryBot.create(:email_template, name: "lembrete", to: "jpimentel@ic.uff.br", subject: "SAPOS: lembrar de etapa", body: "Corpo")
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
      expect(page).to have_content "Templates de Email"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Habilitado", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["despedida", "lembrete", "saudacao"]
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
      expect(page).to have_content "Adicionar Template de Email"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "template"
        fill_in "Template do Destinatário", with: "jpimentel@ic.uff.br"
        fill_in "Template do Assunto", with: "Assunto"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "template")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["template", "despedida", "lembrete", "saudacao"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["despedida", "lembrete", "saudacao"]
    end

    it "should have internal template widget" do
      within("#as_#{plural_name}-create--form") do
        find(:css, ".select_builtin_options").find(:option, text: "devise:email_changed").select_option
      end
      expect(page).to have_field("Nome", with: "devise:email_changed")
      expect(page).to have_field("Template do Destinatário", with: "{{ user.email }}")
      expect(page).to have_field("Template do Assunto", with: "Seu email no SAPOS foi alterado")
      expect(page).to have_css(".CodeMirror-code", text: "1
{{ user.name }},
2
{% if unconfirmed_email %}
3
Seu email do SAPOS está sendo alterado para {{ user.unconfirmed_email }}.
4
{%- else %}
5
Seu email do SAPOS foi alterado para {{ user.email }}.
6
{%- endif %}
7
8
9
{{ variables.notification_footer }}")
    end

    it "should have a codemirror for body" do
      expect(page).to have_selector("#record_body_ + .CodeMirror", visible: true)
    end

    it "should have a selection for internal template" do
      expect(page.all("select.select_builtin_options option").map(&:text)).to eq ([""] + EmailTemplate::BUILTIN_TEMPLATES.keys)
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit student" do
      within(".as_form") do
        fill_in "Nome", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      @record.name = "despedida"
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by variable" do
      fill_in "search", with: "lemb"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["lembrete"]
    end
  end
end

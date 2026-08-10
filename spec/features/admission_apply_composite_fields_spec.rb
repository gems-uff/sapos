# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Campo composto guarda num input escondido a junção dos campos visíveis, e é o
# escondido que o servidor valida. Se ele não acompanhar o que está na tela, o
# candidato leva "não pode ficar em branco" num campo que ele preencheu.
RSpec.describe "Admission apply composite fields", type: :feature, js: true do
  def prepare_process(field_name, field_type, configuration)
    @destroy_later = []
    prepare_city_widget(@destroy_later)

    @template = FactoryBot.create(:form_template, name: "Inscrição")
    @destroy_later << @field = FactoryBot.create(
      :form_field, form_template: @template, name: field_name,
      field_type: field_type, configuration: configuration
    )
    @destroy_later << @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2", simple_url: "mestrado-2026-2",
      form_template: @template,
      start_date: Date.today - 10.days,
      end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
    @destroy_later << @template
  end

  after(:each) do
    Admissions::AdmissionApplication.destroy_all
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  def start_application
    visit new_admission_apply_path(admission_id: @process.simple_id)
    fill_in "record[name]", with: "Ana"
    fill_in "record[email]", with: "ana@ic.uff.br"
  end

  def submitted_composite_value
    Admissions::AdmissionApplication.last
      .filled_form.fields.find { |f| f.form_field_id == @field.id }
      .value
  end

  describe "city field" do
    before(:each) do
      prepare_process(
        "Naturalidade", Admissions::FormField::CITY, '{"required": true}'
      )
    end

    it "carries city, state and country when they are typed" do
      start_application
      find("input[name='country']").set("Brasil")
      find("input[name='state']").set("RJ")
      find("input[name='city']").set("Niteroi")
      click_button "Enviar"

      expect(page).to have_no_selector("input[name='city']")
      expect(submitted_composite_value).to eq "Niteroi <$> RJ <$> Brasil"
    end

    it "carries values that were set without firing events, as autofill does" do
      start_application
      find("input[name='country']").set("Brasil")
      # Tira o foco do país: o change dele já rodou, com cidade e estado vazios,
      # e nada mais dispara evento nos três.
      find("input[name='record[email]']").click
      page.execute_script(<<~JS)
        document.querySelector("input[name='state']").value = "RJ";
        document.querySelector("input[name='city']").value = "Niteroi";
      JS
      click_button "Enviar"

      expect(page).to have_no_selector("input[name='city']")
      expect(submitted_composite_value).to eq "Niteroi <$> RJ <$> Brasil"
    end

    it "carries the values when the form is submitted with Enter" do
      start_application
      find("input[name='country']").set("Brasil")
      find("input[name='state']").set("RJ")
      find("input[name='city']").send_keys("Niteroi", :enter)

      expect(page).to have_no_selector("input[name='city']")
      expect(submitted_composite_value).to eq "Niteroi <$> RJ <$> Brasil"
    end

    it "carries the city chosen from the autocomplete list" do
      start_application
      find("input[name='country']").set("Brasil")
      find("input[name='state']").set("RJ")
      find("input[name='city']").send_keys("Nit")
      expect(page).to have_selector(".ui-autocomplete li", text: "Niteroi")
      find(".ui-autocomplete li", text: "Niteroi").click
      click_button "Enviar"

      expect(page).to have_no_selector("input[name='city']")
      expect(submitted_composite_value).to eq "Niteroi <$> RJ <$> Brasil"
    end
  end

  describe "residency field" do
    before(:each) do
      prepare_process(
        "Residência", Admissions::FormField::RESIDENCY,
        '{"required": true, "number_required": true}'
      )
    end

    it "carries street and number when they are typed" do
      start_application
      find("input[name='city']").set("Rua Passo da Pátria")
      find("input[name='state']").set("156")
      click_button "Enviar"

      expect(page).to have_no_selector("input[name='city']")
      expect(submitted_composite_value).to eq "Rua Passo da Pátria <$> 156"
    end

    it "carries values that were set without firing events" do
      start_application
      find("input[name='city']").set("Rua Passo da Pátria")
      find("input[name='record[email]']").click
      page.execute_script(<<~JS)
        document.querySelector("input[name='state']").value = "156";
      JS
      click_button "Enviar"

      expect(page).to have_no_selector("input[name='city']")
      expect(submitted_composite_value).to eq "Rua Passo da Pátria <$> 156"
    end
  end

  describe "scholarity location" do
    before(:each) do
      prepare_process(
        "Formação Escolar", Admissions::FormField::SCHOLARITY,
        '{"values": ["Graduação"], "statuses": ["Completo"],
          "scholarity_location_required": true}'
      )
    end

    def submitted_location
      Admissions::AdmissionApplication.last
        .filled_form.fields.find { |f| f.form_field_id == @field.id }
        .scholarities.first.location
    end

    it "carries city and state when they are typed" do
      start_application
      click_link "Adicionar formação"
      find(".scholarity-location input[name='state']").set("RJ")
      find(".scholarity-location input[name='city']").set("Niteroi")
      click_button "Enviar"

      expect(page).to have_no_selector(".scholarity-location")
      expect(submitted_location).to eq "Niteroi, RJ"
    end

    it "carries values that were set without firing events" do
      start_application
      click_link "Adicionar formação"
      find(".scholarity-location input[name='state']").set("RJ")
      find("input[name='record[email]']").click
      page.execute_script(<<~JS)
        document.querySelector(".scholarity-location input[name='city']")
          .value = "Niteroi";
      JS
      click_button "Enviar"

      expect(page).to have_no_selector(".scholarity-location")
      expect(submitted_location).to eq "Niteroi, RJ"
    end
  end
end

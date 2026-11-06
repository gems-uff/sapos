# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Reproducao da issue #703, que ainda nao foi consertada: o exemplo dela esta
# marcado como pending e falha hoje sem deixar a suite vermelha. Quando o
# conserto chegar ele passa, e o RSpec acusa o pending que deixou de falhar --
# e a hora de tirar a marca. O controle nao e pending: e ele que prova que o
# cenario monta, e que o pending falha pela issue e nao por outro motivo.

RSpec.describe "Escolaridade com id de item repetido", type: :feature, js: true do
  before(:each) do
    template = FactoryBot.create(:form_template, name: "Inscricao")
    campo = FactoryBot.create(
      :form_field, form_template: template, name: "Formacao",
      field_type: Admissions::FormField::SCHOLARITY,
      configuration: { values: ["Graduação", "Mestrado"], statuses: ["Completo", "Em andamento"] }.to_json
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado", simple_url: "escolaridade-#{SecureRandom.hex(4)}",
      form_template: template, start_date: Date.today - 10.days,
      end_date: Date.today + 10.days, edit_date: Date.today + 20.days
    )
    filled_form = FactoryBot.create(:filled_form, form_template: template, is_filled: true)
    preenchido = FactoryBot.create(:filled_form_field, filled_form: filled_form, form_field: campo, value: nil)
    @graduacao = FactoryBot.create(:filled_form_field_scholarity, filled_form_field: preenchido,
      level: "Graduação", location: "Niteroi, RJ")
    @mestrado = FactoryBot.create(:filled_form_field_scholarity, filled_form_field: preenchido,
      level: "Mestrado", location: "Campinas, SP")
    @application = FactoryBot.create(:admission_application, admission_process: @process, filled_form: filled_form)
  end

  def reenviar_sem_mudar
    visit edit_admission_apply_path(admission_id: @process.simple_id, id: @application.token)
    expect(page).to have_selector(".scholarity-location", count: 2)
    find("input[type=submit]", match: :first).click
    expect(page).to have_no_current_path(/edit/)
  end

  it "grava em cada item o próprio local, mesmo com ids sorteados iguais", pending: "issue #703" do
    allow(Random).to receive(:rand).and_call_original
    allow(Random).to receive(:rand).with(10000).and_return(4242)

    reenviar_sem_mudar

    expect(@graduacao.reload.location).to eq "Niteroi, RJ"
    expect(@mestrado.reload.location).to eq "Campinas, SP"
  end

  it "controle: sem sorteio igual, cada item fica com o próprio local" do
    reenviar_sem_mudar

    expect(@graduacao.reload.location).to eq "Niteroi, RJ"
    expect(@mestrado.reload.location).to eq "Campinas, SP"
  end
end

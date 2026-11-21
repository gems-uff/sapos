# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Reproducao da issue #701, que ainda nao foi consertada: o exemplo dela esta
# marcado como pending e falha hoje sem deixar a suite vermelha. Quando o
# conserto chegar ele passa, e o RSpec acusa o pending que deixou de falhar --
# e a hora de tirar a marca. O controle nao e pending: e ele que prova que o
# cenario monta, e que o pending falha pela issue e nao por outro motivo.

RSpec.describe "Cartas com duas edicoes inline abertas", type: :feature, js: true do
  include AdmissionsScenarioHelpers

  before(:each) do
    login_as(create_confirmed_user([FactoryBot.create(:role_administrador)]))
    template = create_admission_template("Inscricao", { "Nome social" => Admissions::FormField::STRING })
    letter = FactoryBot.create(:form_template, template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER)
    @process = create_closed_admission_process(
      template, simple_url: "cartas-#{SecureRandom.hex(4)}",
      letter_template: letter, min_letters: 0, max_letters: 3
    )
    @phase = add_phase(@process, 1)
    @a = create_application(@process, name: "Ana", admission_phase: @phase)
    @b = create_application(@process, name: "Bia", admission_phase: @phase)
    visit admission_applications_path(
      admission_process_id: @process.id, admission_phase_id: @phase.id, simple_view: "1"
    )
  end

  def edit_div(application)
    "#as_admissions__admission_applications-#{application.id}-edit-div"
  end

  def open_override_edit(application)
    within(find("tr", text: application.name)) do
      find(".advanced-config").click
      find(".edit-override").click
    end
    expect(page).to have_selector(edit_div(application))
  end

  it "grava em B a carta acrescentada em B", :aggregate_failures, pending: "issue #701" do
    open_override_edit(@a)
    open_override_edit(@b)

    find(edit_div(@b)).find(".add-letter").click
    nova = find(".letter_request", match: :first)
    nova.find("input[type=email]").set("prof@example.com")
    nova.find("input[name$='[name]']").set("Prof")
    within(nova.find(:xpath, "./ancestor::form")) do
      find("input[type='submit'][value='Atualizar']", visible: :all).click
    end
    # A edicao salva fecha, e com ela a carta some da tela.
    expect(page).to have_no_selector(".letter_request")

    expect(@b.reload.letter_requests.pluck(:email)).to eq ["prof@example.com"]
    expect(@a.reload.letter_requests).to be_empty
  end

  it "controle: com só B aberta, a carta vai para B" do
    open_override_edit(@b)
    find(edit_div(@b)).find(".add-letter").click
    expect(page).to have_selector("#{edit_div(@b)} .letter_request", count: 1)
  end
end

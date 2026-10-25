# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Reproducao da issue #702, que ainda nao foi consertada: o exemplo dela esta
# marcado como pending e falha hoje sem deixar a suite vermelha. Quando o
# conserto chegar ele passa, e o RSpec acusa o pending que deixou de falhar --
# e a hora de tirar a marca. O controle nao e pending: e ele que prova que o
# cenario monta, e que o pending falha pela issue e nao por outro motivo.

RSpec.describe "Atualizar com duas edicoes inline abertas", type: :feature, js: true do
  include AdmissionsScenarioHelpers

  before(:each) do
    login_as(create_confirmed_user([FactoryBot.create(:role_administrador)]))
    template = create_admission_template("Inscricao", {
      "Bolsa" => {
        field_type: Admissions::FormField::RADIO,
        configuration: { "required" => true, "values" => ["Sim", "Nao"] }
      }
    })
    @process = create_closed_admission_process(template, simple_url: "submit-#{SecureRandom.hex(4)}")
    @phase = add_phase(@process, 1)
    @a = create_application(@process, name: "Ana", admission_phase: @phase, fields: { "Bolsa" => "Sim" })
    @b = create_application(@process, name: "Bia", admission_phase: @phase)
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

  # B com o formulario do candidato habilitado e o radio obrigatorio vazio: a
  # validacao de B reprova. A nao tem nada invalido.
  def abrir_as_duas(habilitar_b:)
    visit admission_applications_path(
      admission_process_id: @process.id, admission_phase_id: @phase.id, simple_view: "1"
    )
    open_override_edit(@a)
    open_override_edit(@b)
    within(edit_div(@b)) { check "Habilitar formulário nesta submissão" } if habilitar_b
  end

  def atualizar(application)
    within(find(edit_div(application)).find(:xpath, "./ancestor::form")) do
      find("input[type='submit'][value='Atualizar']", visible: :all).click
    end
    wait_for_ajax
  end

  it "salva A mesmo com B aberta e inválida", pending: "issue #702" do
    abrir_as_duas(habilitar_b: true)
    atualizar(@a)
    expect(page).to have_no_selector(edit_div(@a))
  end

  it "controle: salva A com B aberta e válida" do
    abrir_as_duas(habilitar_b: false)
    atualizar(@a)
    expect(page).to have_no_selector(edit_div(@a))
  end
end

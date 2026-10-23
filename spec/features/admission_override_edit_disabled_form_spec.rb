# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Na edicao administrativa da candidatura (override), o formulario do candidato
# nasce desabilitado: o administrador esta ali para lancar resultado de fase, nao
# para preencher a inscricao no lugar de quem se inscreveu. Quem desabilita e o
# bloco guardado por can_disable_submission em _filled_form_template.
#
# Tres coisas dependem de *como* ele desabilita, e nenhuma delas aparece em
# request spec -- so o navegador as expoe. Um campo desabilitado por um
# <fieldset disabled> ancestral nao tem o atributo `disabled`, e a propriedade
# `disabled` dele continua false; so o seletor :disabled enxerga o fieldset.
#
# 1. As validacoes de cliente registradas em window.customFormValidations tem de
#    se calar com o formulario desabilitado. Se alguma nao se cala, o campo
#    obrigatorio vazio veta o submit em _custom_forms_form_column, e o botao
#    "Atualizar" para de funcionar sem dizer nada -- o sintoma da #677.
#
# 2. O jquery_ujs tambem veta o submit quando acha campo obrigatorio vazio, e o
#    seletor dele (requiredInputSelector) exclui so quem tem o atributo
#    `disabled`. O RADIO nao emite `required` e nao passa por ali; o STRING
#    emite, e e por isso que os dois tem exemplo proprio.
#
# 3. O asterisco vermelho de campo obrigatorio vem de custom/admissions.scss por
#    seletor ancorado em .filled-form-html-id. Envolver os campos em outro
#    elemento pode tira-los do alcance do seletor e apagar o asterisco nesta
#    tela -- que nao e coberta por admission_apply_required_marker_spec,
#    restrito a tela publica.
RSpec.describe "Candidatura: edicao administrativa com formulario desabilitado",
               type: :feature, js: true do
  include AdmissionsScenarioHelpers

  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm])
    login_as(@user)
  end

  def setup_application(field_name, field_definition)
    @template = create_admission_template("Inscricao", {
      field_name => field_definition
    })
    @process = create_closed_admission_process(
      @template, simple_url: "desabilitado-#{SecureRandom.hex(4)}"
    )
    @phase = add_phase(@process, 1)
    @application = create_application(
      @process, name: "Ana", admission_phase: @phase
    )
  end

  def edit_div_selector
    "#as_admissions__admission_applications-#{@application.id}-edit-div"
  end

  def open_override_edit
    visit admission_applications_path(
      admission_process_id: @process.id, admission_phase_id: @phase.id,
      simple_view: "1"
    )
    within(find("tr", text: @application.name)) do
      find(".advanced-config").click
      find(".edit-override").click
    end
    expect(page).to have_selector(edit_div_selector)
  end

  def field_input(field_name, selector)
    find("#{edit_div_selector} li.form-element", text: field_name)
      .find(selector, visible: :all, match: :first)
  end

  def submit_override_edit
    form = find(edit_div_selector).find(:xpath, "./ancestor::form")
    within(form) do
      find("input[type='submit'][value='Atualizar']", visible: :all).click
    end
    wait_for_ajax
  end

  it "nao bloqueia o Atualizar por causa de RADIO obrigatorio do formulario desabilitado" do
    setup_application("Bolsa", {
      field_type: Admissions::FormField::RADIO,
      configuration: { "required" => true, "values" => ["Sim", "Nao"] }
    })
    open_override_edit

    # Precondicao: o formulario do candidato esta desabilitado nesta submissao --
    # medida pelo estado efetivo, que e o que o usuario ve.
    expect(field_input("Bolsa", "input[type=radio]")).to be_disabled

    submit_override_edit

    # O submit tem de sair: a linha sai do modo de edicao. Se o veto disparar,
    # a linha fica aberta para sempre, sem mensagem nenhuma.
    expect(page).to have_no_selector(edit_div_selector)
  end

  it "nao bloqueia o Atualizar por causa de STRING obrigatorio do formulario desabilitado" do
    setup_application("Nome social", {
      field_type: Admissions::FormField::STRING,
      configuration: { "required" => true }
    })
    open_override_edit

    # Precondicao: o campo emite `required` -- e o que o poe no alcance do
    # jquery_ujs -- e esta desabilitado pelo estado efetivo.
    expect(field_input("Nome social", "input[required]")).to be_disabled

    submit_override_edit

    expect(page).to have_no_selector(edit_div_selector)
  end

  it "mantem o asterisco vermelho no rotulo do campo obrigatorio" do
    setup_application("Bolsa", {
      field_type: Admissions::FormField::RADIO,
      configuration: { "required" => true, "values" => ["Sim", "Nao"] }
    })
    open_override_edit

    marker = page.evaluate_script(<<~JS)
      (function () {
        var scope = document.querySelector(#{edit_div_selector.to_json});
        var label = Array.from(scope.querySelectorAll("li.form-element dt label"))
          .find(function (l) { return l.textContent.trim() === "Bolsa"; });
        if (!label) { return null; }
        var s = getComputedStyle(label, "::after");
        return { content: s.content, color: s.color };
      })()
    JS

    expect(marker).not_to be_nil
    expect(marker["content"]).to eq('"*"')
    expect(marker["color"]).to eq("rgb(255, 0, 0)")
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Na edicao administrativa da candidatura (override), o formulario do candidato
# nasce desabilitado: o administrador esta ali para lancar resultado de fase, nao
# para preencher a inscricao no lugar de quem se inscreveu. Quem desabilita e o
# bloco guardado por can_disable_submission em _filled_form_template.
#
# Duas coisas dependem de *como* ele desabilita, e nenhuma delas aparece em
# request spec -- so o navegador as expoe:
#
# 1. As validacoes de cliente registradas em window.customFormValidations se
#    calam lendo `input.disabled`. Essa propriedade reflete o atributo do proprio
#    elemento, nao o do <fieldset> que o contem: dentro de um fieldset
#    desabilitado ela continua false. Se a guarda nao dispara, a validacao do
#    campo obrigatorio vazio devolve false, o handler de submit de
#    _custom_forms_form_column chama preventDefault, e o botao "Atualizar" para
#    de funcionar sem dizer nada -- o mesmo sintoma da #677, por outra porta.
#    Quem le o estado efetivo e o seletor :disabled, que anda pelos ancestrais.
#
# 2. O asterisco vermelho de campo obrigatorio vem de custom/admissions.scss por
#    seletor de irmaos ancorado em .filled-form-html-id. Envolver os campos em
#    qualquer elemento os tira da irmandade e apaga o asterisco nesta tela -- que
#    nao e coberta por admission_apply_required_marker_spec, restrito a tela
#    publica.
RSpec.describe "Candidatura: edicao administrativa com formulario desabilitado",
               type: :feature, js: true do
  include AdmissionsScenarioHelpers

  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm])
    @template = create_admission_template("Inscricao", {
      "Bolsa" => {
        field_type: Admissions::FormField::RADIO,
        configuration: { "required" => true, "values" => ["Sim", "Nao"] }
      }
    })
    @process = create_closed_admission_process(
      @template, simple_url: "desabilitado-#{SecureRandom.hex(4)}"
    )
    @phase = add_phase(@process, 1)
    @application = create_application(
      @process, name: "Ana", admission_phase: @phase
    )
    login_as(@user)
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
    expect(page).to have_selector(edit_div_selector, wait: 10)
  end

  it "nao bloqueia o Atualizar por causa de campo obrigatorio do formulario desabilitado" do
    open_override_edit

    # Precondicao: o formulario do candidato esta desabilitado nesta submissao --
    # medida pelo estado efetivo, que e o que o usuario ve.
    expect(first("#{edit_div_selector} input[type=radio]", visible: :all))
      .to be_disabled

    form = find(edit_div_selector).find(:xpath, "./ancestor::form")
    within(form) do
      find("input[type='submit'][value='Atualizar']", visible: :all).click
    end
    wait_for_ajax

    # O submit tem de sair: a linha sai do modo de edicao. Enquanto a guarda
    # `input.disabled` nao enxergar o fieldset, o handler de submit chama
    # preventDefault e a linha fica aberta para sempre, sem mensagem nenhuma.
    expect(page).to have_no_selector(edit_div_selector, wait: 10)
  end

  it "mantem o asterisco vermelho no rotulo do campo obrigatorio" do
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

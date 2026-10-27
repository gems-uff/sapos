# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# As validacoes de cliente do formulario de inscricao montam a mensagem de erro
# com o nome do campo e, nos campos de arquivo, com a lista de extensoes -- texto
# que quem configura o template escreve. Essa mensagem vive dentro de um <script>,
# onde o escape de HTML nao protege nada: o texto tem de sair como literal de
# string JavaScript. Se ele cair cru num template literal, uma crase no nome
# quebra o script inteiro (e o campo perde a validacao) e um `${...}` deixa de
# ser texto.
#
# Cada campo abaixo exercita um ramo de mensagem. O exemplo monta o estado que
# faz cada validacao falhar e chama as validacoes registradas, como o submit faz.
RSpec.describe "Admission apply: texto configurado nas mensagens de validação", type: :feature, js: true do
  include AdmissionsScenarioHelpers

  def marker(n)
    "${(window.__injetado ||= []).push(#{n})}"
  end

  let(:names) do
    {
      radio: "Bolsa #{marker(1)}",
      backtick: "Nota `final`",
      date: "Data #{marker(2)}",
      checkbox: "Areas #{marker(3)}",
      big_file: "Comprovante #{marker(4)}",
      wrong_file: "Historico #{marker(5)}",
      student_date: "Nascimento #{marker(7)}",
      photo: "Foto #{marker(8)}",
    }
  end

  before(:each) do
    template = create_admission_template("Inscricao", {
      names[:radio] => {
        field_type: Admissions::FormField::RADIO,
        configuration: { "required" => true, "values" => ["Sim", "Nao"] }
      },
      names[:backtick] => {
        field_type: Admissions::FormField::RADIO,
        configuration: { "required" => true, "values" => ["Sim", "Nao"] }
      },
      names[:date] => {
        field_type: Admissions::FormField::DATE,
        configuration: {}
      },
      names[:checkbox] => {
        field_type: Admissions::FormField::COLLECTION_CHECKBOX,
        configuration: { "values" => ["A", "B"], "minselection" => 1, "maxselection" => 2 }
      },
      names[:big_file] => {
        field_type: Admissions::FormField::FILE,
        configuration: { "values" => [".pdf"] }
      },
      names[:wrong_file] => {
        field_type: Admissions::FormField::FILE,
        configuration: { "values" => [".pdf", marker(6)] }
      },
      names[:student_date] => {
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: { "field" => "birthdate" }
      },
      names[:photo] => {
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: { "field" => "photo", "values" => [".png"] }
      },
    })
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado", simple_url: "mensagens-#{SecureRandom.hex(4)}",
      form_template: template,
      start_date: Date.today - 10.days,
      end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  def field_js
    <<~JS
      function fieldLi(name) {
        var label = Array.from(document.querySelectorAll("li.form-element dt label"))
          .find(function (l) { return l.textContent.trim() === name; });
        return label ? label.closest("li") : null;
      }
    JS
  end

  def set_text(name, value)
    page.execute_script(<<~JS)
      #{field_js}
      fieldLi(#{name.to_json}).querySelector("input[type=text]").value = #{value.to_json};
    JS
  end

  def set_file(name, filename, size)
    page.execute_script(<<~JS)
      #{field_js}
      var dt = new DataTransfer();
      dt.items.add(new File([new Uint8Array(#{size})], #{filename.to_json}));
      fieldLi(#{name.to_json}).querySelector("input[type=file]").files = dt.files;
    JS
  end

  def run_validations
    page.execute_script(<<~JS)
      Object.values(window.customFormValidations).flat().forEach(function (v) {
        try { v(); } catch (e) {}
      });
    JS
  end

  def messages(name)
    page.evaluate_script(<<~JS)
      (function () {
        #{field_js}
        var li = fieldLi(#{name.to_json});
        if (!li) { return null; }
        return Array.from(li.querySelectorAll("input"))
          .map(function (i) { return i.validationMessage; })
          .filter(function (m) { return m; });
      })()
    JS
  end

  def expect_literal_message(key)
    expect(messages(names[key])).to include(a_string_starting_with(names[key])), key.to_s
  end

  it "mostra o texto configurado como literal, sem executa-lo nem quebrar a validacao", :aggregate_failures do
    visit new_admission_apply_path(admission_id: @process.simple_id)

    set_text(names[:date], "99/99/9999")
    set_text(names[:student_date], "99/99/9999")
    set_file(names[:big_file], "grande.pdf", 16 * 1024 * 1024)
    set_file(names[:wrong_file], "errado.txt", 10)
    set_file(names[:photo], "grande.png", 16 * 1024 * 1024)
    run_validations

    %i[radio backtick date checkbox big_file wrong_file student_date photo].each do |key|
      expect_literal_message(key)
    end
    expect(messages(names[:wrong_file]).join).to include(marker(6))

    # A foto tem dois ramos de mensagem: o do tamanho, acima, e o da extensao.
    set_file(names[:photo], "errada.txt", 10)
    run_validations
    expect_literal_message(:photo)

    expect(page.evaluate_script("window.__injetado")).to be_nil
  end
end

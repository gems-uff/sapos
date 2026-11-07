# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Formularios de configuracao do processo seletivo que nenhum exemplo abria
# (#720): os helpers de coluna de relatorio, ranking e campo de formulario --
# nome com autocomplete, condicao de formulario e configuracao de campo -- so
# rodam quando o active_scaffold monta a tela, inclusive dentro de subform.
RSpec.describe "Formularios de configuracao do processo seletivo", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_config_adm@ic.uff.br", "Adm"
    )
  end

  def html
    Nokogiri::HTML(response.body)
  end

  # form_field_name_widget: campo de texto com o nome e o autocomplete, que
  # pede so campos de carta quando recebe in_letter.
  def campo_nome(valor)
    html.css("input.text-input").find { |input| input["value"] == valor }
  end

  def script_do_campo(campo)
    html.css("script").map(&:text).find { |js| js.include?("##{campo["id"]}`") }
  end

  def condicao_de_formulario
    html.css("input[id^='widget_']").find { |input| input["name"].end_with?("[form_condition]") }
  end

  describe "colunas de relatorio" do
    it "abre o novo com o nome que autocompleta campos de carta" do
      get new_admission_report_column_path

      expect(response).to have_http_status(:ok)
      campo = html.css("input[name='record[name]']").first
      expect(campo["class"]).to include("text-input")
      expect(script_do_campo(campo)).to include("request.in_letter = true")
    end
  end

  describe "configuracoes de relatorio" do
    it "abre o novo com a condicao de formulario e os grupos padrao" do
      get new_admission_report_config_path

      expect(response).to have_http_status(:ok)
      expect(condicao_de_formulario).to be_present
      expect(response.body).to include("create_form_condition")
      # Os grupos de init_default trazem o seletor de colunas, com os titulos
      # traduzidos de admission_report_group.
      expect(html.css("i.fa-eye[title='Mostrar configuração']")).not_to be_empty
      expect(html.css("i.fa-eye-slash[title='Esconder configuração']")).not_to be_empty
    end

    it "edita com a coluna de ranking, sem restringir o autocomplete a carta" do
      config = FactoryBot.create(:admission_report_config)
      FactoryBot.create(:ranking_column, name: "Nota final", admission_report_config: config)

      get edit_admission_report_config_path(config)

      expect(response).to have_http_status(:ok)
      campo = campo_nome("Nota final")
      expect(campo["name"]).to match(/\Arecord\[ranking_columns\]\[\d+\]\[name\]\z/)
      script = script_do_campo(campo)
      expect(script).to include("autocomplete")
      expect(script).not_to include("in_letter")
    end

    it "edita com o grupo e sua coluna, autocompletando campos de carta" do
      config = FactoryBot.create(:admission_report_config)
      grupo = FactoryBot.create(:admission_report_group, admission_report_config: config)
      FactoryBot.create(:admission_report_column, admission_report_group: grupo, name: "Campo do grupo")

      get edit_admission_report_config_path(config)

      expect(response).to have_http_status(:ok)
      campo = campo_nome("Campo do grupo")
      expect(campo["name"]).to match(/\[columns\]\[\d+\]\[name\]\z/)
      expect(script_do_campo(campo)).to include("request.in_letter = true")
    end
  end

  describe "grupos de relatorio" do
    # Fora de AdmissionReportConfigs e AdmissionProcesses a partial das colunas
    # cai no form_association comum, que monta o subform com o helper do grupo.
    it "edita com a coluna no subform comum" do
      grupo = FactoryBot.create(:admission_report_group)
      FactoryBot.create(:admission_report_column, admission_report_group: grupo, name: "Coluna solta")

      get edit_admission_report_group_path(grupo)

      expect(response).to have_http_status(:ok)
      campo = campo_nome("Coluna solta")
      expect(campo["name"]).to match(/\Arecord\[columns\]\[\d+\]\[name\]\z/)
      expect(script_do_campo(campo)).to include("request.in_letter = true")
      expect(html.css("i.fa-eye[title='Mostrar configuração']")).to be_empty
    end
  end

  describe "colunas de ranking" do
    it "abre o novo com o nome que autocompleta" do
      get new_ranking_column_path

      expect(response).to have_http_status(:ok)
      campo = html.css("input[name='record[name]']").first
      expect(script_do_campo(campo)).to include("autocomplete")
      expect(script_do_campo(campo)).not_to include("in_letter")
    end
  end

  describe "maquinas de ranking" do
    it "abre o novo com a condicao de formulario" do
      get new_ranking_machine_path

      expect(response).to have_http_status(:ok)
      expect(condicao_de_formulario["value"]).to eq("{}")
      expect(response.body).to include("create_form_condition")
    end
  end

  # A partial _configuration_form_column monta o editor de configuracao do
  # campo com as traducoes de form_field (form_field_t) e a lista de colunas
  # de aluno (student_t), pelo helper de cada controller.
  describe "configuracao de campo de formulario" do
    def editor_de_configuracao
      html.css("script").map(&:text).find { |js| js.include?("form_field_config_base") }
    end

    def confere_editor
      expect(html.css("i.fa-eye[title='Mostrar configuração']")).not_to be_empty
      expect(editor_de_configuracao).to include("\"show_config\":\"Mostrar configuração\"")
      expect(editor_de_configuracao).to include("[\"name\",\"Nome\"]")
      expect(editor_de_configuracao).to include("[\"mother_name\",\"Nome da mãe\"]")
    end

    it "abre o novo campo" do
      get new_form_field_path

      expect(response).to have_http_status(:ok)
      confere_editor
    end

    it "edita o formulario com o campo no subform" do
      template = FactoryBot.create(:form_template)
      FactoryBot.create(:form_field, form_template: template, name: "Campo existente")

      get edit_form_template_path(template)

      expect(response).to have_http_status(:ok)
      expect(html.css("input[value='Campo existente']")).not_to be_empty
      confere_editor
    end

    it "edita o modelo de consolidacao com o campo no subform" do
      template = FactoryBot.create(
        :form_template, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
      )
      FactoryBot.create(
        :form_field, form_template: template, name: "Campo consolidado",
        field_type: Admissions::FormField::CODE, configuration: JSON.dump(
          "code" => "1", "template_type" => Admissions::FormField::LIQUID,
          "code_type" => "number"
        )
      )

      get edit_consolidation_template_path(template)

      expect(response).to have_http_status(:ok)
      expect(html.css("input[value='Campo consolidado']")).not_to be_empty
      confere_editor
    end
  end
end

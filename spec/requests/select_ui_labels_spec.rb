# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Guarda do salto do active_scaffold para a serie 4.3 (#621).
#
# Ate a 4.2 a conversao de valor gravado em rotulo estava embutida em
# format_column_value: com form_ui :select ou :radio e options declaradas, ele
# procurava o par [rotulo, valor] e exibia o rotulo. A 4.3.0 tirou esse bloco
# de la e o transformou em list UI proprio -- active_scaffold_column_select,
# que chama convert_value_to_label. Como list_ui cai para form_ui e show_ui cai
# para list_ui, e o SAPOS nao declara nenhum dos dois, o conjunto de colunas
# alcancado e o mesmo: a refatoracao deveria ser invisivel na tela.
#
# "Deveria" e o que este arquivo mede. As tres colunas do sistema cujas options
# sao pares [rotulo, valor] -- students.sex, professors.sex e
# professors.civil_status -- exibem o rotulo na visao de leitura, e nenhuma
# tinha cobertura que olhasse o texto exibido. Se um salto futuro mover a
# conversao outra vez e deixa-la cair no caminho, a tela passa a mostrar o
# codigo gravado ("M" no lugar de "Masculino") e o exemplo cai aqui, em vez de
# a diferenca so aparecer em producao.
RSpec.describe "Select UI labels", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "select_ui_admin@ic.uff.br")
    sign_in @admin
  end

  # O texto da celula de uma coluna na tela de show. O active_scaffold marca
  # cada valor com <dd class="<coluna>-view">. Levanta se a celula nao existir,
  # para o exemplo nao passar a toa quando a coluna sai da configuracao.
  def show_cell(column)
    node = Nokogiri::HTML(response.body).at_css("dd.#{column}-view")
    raise "tela sem a celula de #{column}" if node.nil?
    node.text.strip
  end

  describe "GET student show" do
    it "renders the label of the option, not the stored code" do
      student = FactoryBot.create(:student, sex: "M")

      get student_path(student)

      expect(response).to have_http_status(:ok)
      expect(show_cell("sex")).to eq "Masculino"
    end

    # Contraponto: em civil_status o SAPOS passa options como lista de strings,
    # entao rotulo e valor sao o mesmo texto e a conversao e inocua. Sem este
    # exemplo, uma conversao que devolvesse sempre o primeiro rotulo passaria
    # pelo exemplo de cima.
    it "keeps the stored text when the option has no separate label" do
      student = FactoryBot.create(:student, civil_status: "Casado(a)")

      get student_path(student)

      expect(show_cell("civil_status")).to eq "Casado(a)"
    end
  end

  describe "GET professor show" do
    it "renders the labels of the options, not the stored codes" do
      professor = FactoryBot.create(
        :professor, sex: "F", civil_status: "solteiro"
      )

      get professor_path(professor)

      expect(response).to have_http_status(:ok)
      expect(show_cell("sex")).to eq "Feminino"
      expect(show_cell("civil_status")).to eq "Solteiro(a)"
    end
  end
end

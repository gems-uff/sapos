# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Professor novo com area e linha de pesquisa no mesmo envio (issue #761):
# ProfessorResearchLine#verify_area pergunta ao banco pelas areas do
# professor, e a area que chega no mesmo envio ainda nao esta la.
RSpec.describe "Area e linha de pesquisa no mesmo envio do professor", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.arealinha@ic.uff.br", "Adm")
    @area = FactoryBot.create(:research_area)
    @linha = FactoryBot.create(:research_line, research_area: @area)
  end

  def params_novo(com_linha:, area: @area)
    record = { name: "Prof Novo", cpf: "area-linha-cpf",
               professor_research_areas: { "1000" => { research_area: area.id.to_s } } }
    record[:professor_research_lines] = { "1001" => { research_line: @linha.id.to_s } } if com_linha
    { record: record }
  end

  it "controle: professor novo so com a area e gravado" do
    post professors_path, params: params_novo(com_linha: false)
    expect(Professor.find_by(cpf: "area-linha-cpf")&.research_areas).to eq([@area])
  end

  it "controle: linha de area que o professor nao tem e recusada" do
    post professors_path, params: params_novo(com_linha: true, area: FactoryBot.create(:research_area))
    expect(Professor.find_by(cpf: "area-linha-cpf")).to be_nil
  end

  it "professor novo com a area e a linha dela no mesmo envio e gravado", pending: "issue #761" do
    post professors_path, params: params_novo(com_linha: true)
    professor = Professor.find_by(cpf: "area-linha-cpf")
    expect(professor&.research_lines).to eq([@linha])
  end
end

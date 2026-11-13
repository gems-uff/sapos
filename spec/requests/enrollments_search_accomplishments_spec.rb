# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Busca de matriculas pela etapa concluida ate uma data (field_search do
# active_scaffold, que chama condition_for_accomplishments_column com o valor
# do formulario).
RSpec.describe "Busca de matriculas por etapa concluida", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_etapa@ic.uff.br", "Adm")
    @fase = FactoryBot.create(:phase)
    @concluiu = FactoryBot.create(:enrollment, enrollment_number: "M-CONCLUIU")
    @depois = FactoryBot.create(:enrollment, enrollment_number: "M-DEPOIS")
    @nao = FactoryBot.create(:enrollment, enrollment_number: "M-NAO")
    FactoryBot.create(:accomplishment, enrollment: @concluiu, phase: @fase,
      conclusion_date: Date.new(2020, 1, 10))
    FactoryBot.create(:accomplishment, enrollment: @depois, phase: @fase,
      conclusion_date: Date.new(2022, 1, 10))
  end

  def busca(phase:, year: "2021", month: "1", day: "1")
    get enrollments_path, params: {
      search: { accomplishments: { phase: phase, year: year, month: month, day: day } }
    }
    expect(response).to have_http_status(:ok)
    %w[M-CONCLUIU M-DEPOIS M-NAO].select { |numero| response.body.include?(numero) }
  end

  it "lista so quem concluiu a etapa ate a data" do
    expect(busca(phase: @fase.id.to_s)).to eq(["M-CONCLUIU"])
  end

  it "aceita dia e mes de um digito" do
    expect(busca(phase: @fase.id.to_s, year: "2022", month: "2", day: "1")).to eq(["M-CONCLUIU", "M-DEPOIS"])
  end

  it "trata a fase como numero, sem levar o texto para o SQL" do
    expect(busca(phase: "#{@fase.id}) OR (1=1")).not_to include("M-NAO")
  end

  it "trata a data como data, sem levar o texto para o SQL" do
    # O dia vale 1: so quem concluiu ate 01/01/2021.
    expect(busca(phase: @fase.id.to_s, day: "1') OR ('1'='1")).to eq(["M-CONCLUIU"])
  end
end

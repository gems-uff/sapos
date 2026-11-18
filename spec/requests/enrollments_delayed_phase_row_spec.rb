# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Busca de matriculas com etapa atrasada em "todas": cada matricula ganha uma
# linha "Etapas atrasadas" com o nome das etapas (EnrollmentsHelper#
# display_action_links), que tem de sair escapado.
RSpec.describe "Linha de etapas atrasadas na busca de matriculas", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_atraso@ic.uff.br", "Adm")
  end

  def busca(nome_da_etapa)
    nivel = FactoryBot.create(:level)
    fase = FactoryBot.create(:phase, name: nome_da_etapa)
    FactoryBot.create(:phase_duration, phase: fase, level: nivel)
    FactoryBot.create(:enrollment, level: nivel, admission_date: Date.new(2020, 3, 1))
    hoje = Date.current
    get enrollments_path, params: { search: { delayed_phase: {
      phase: "all", year: hoje.year.to_s, month: hoje.month.to_s, day: hoje.day.to_s
    } } }
    expect(response).to have_http_status(:ok)
    response.body
  end

  it "mostra o nome da etapa atrasada" do
    expect(busca("Proposta de Tese")).to include("Etapas atrasadas", "Proposta de Tese")
  end

  it "escapa o nome da etapa atrasada" do
    corpo = busca("<b>marcado</b>")

    expect(corpo).to include("Etapas atrasadas", "&lt;b&gt;marcado&lt;/b&gt;")
    expect(corpo).not_to include("<b>marcado</b>")
  end
end

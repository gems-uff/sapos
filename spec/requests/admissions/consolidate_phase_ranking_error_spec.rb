# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Consolidar a fase grava o status dos candidatos, calcula os rankings da fase
# e só então move os aprovados. Exceção no ranking interrompe no meio: os
# aprovados ficam "Aprovado" na fase atual, sem passar à seguinte.
RSpec.describe "Consolidação com erro no ranking da fase", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "ranking_error_admin@ic.uff.br")
    template = create_admission_template(
      "Inscrição", { "nota" => Admissions::FormField::NUMBER, "extra" => Admissions::FormField::NUMBER }
    )
    @process = create_closed_admission_process(template, simple_url: "ranking-error")
    @phase1 = add_phase(@process, 1, name: "Análise",
      approval_condition: field_condition("nota", Admissions::FormCondition::GE, "7"))
    @phase2 = add_phase(@process, 2, name: "Entrevista")
    add_committee(@phase2, [professor_user("ranking-error-member@ic.uff.br")])
    # Coluna sobre um campo que a candidatura não preencheu
    @ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "extra")
    FactoryBot.create(:admission_process_ranking, admission_process: @process,
      ranking_config: @ranking, admission_phase: @phase1, order: 1)
    @approved = create_application(@process, fields: { "nota" => "8" }, admission_phase: @phase1)
  end

  def consolidate
    post consolidate_phase_admission_process_path(@process), params: { consolidate_phase_id: @phase1.id }
  end

  it "ignorando o erro de ranking, o aprovado passa de fase" do
    @ranking.update!(behavior_on_invalid_ranking: Admissions::RankingConfig::IGNORE_RANKING)
    consolidate
    expect(@approved.reload.admission_phase).to eq(@phase2)
  end

  it "com erro de ranking, a consolidação é recusada" do
    @ranking.update!(behavior_on_invalid_ranking: Admissions::RankingConfig::EXCEPTION_RANKING)
    consolidate
    expect(flash[:error]).to include("extra")
  end

  it "com erro de ranking, nenhum status fica gravado", pending: "issue #754" do
    @ranking.update!(behavior_on_invalid_ranking: Admissions::RankingConfig::EXCEPTION_RANKING)
    consolidate
    @approved.reload
    expect(@approved.admission_phase).to eq(@phase1)
    expect(@approved.status).to be_nil
  end
end

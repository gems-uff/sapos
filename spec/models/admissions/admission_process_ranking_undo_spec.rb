# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Recalcular um ranking encadeado a uma consolidação depois de desfazê-la
# (#712). A nota vem do formulário de consolidação da fase 1, e a precondição
# exige que ela exista, como num ranking de bolsas: desfeita a consolidação, a
# precondição tira o candidato do cálculo em vez de abortá-lo, e o resultado
# anterior dele não pode ficar gravado.
RSpec.describe Admissions::AdmissionProcessRanking, "recálculo depois do desfazer", type: :model do
  before(:each) do
    @process = create_closed_admission_process(
      create_admission_template("Inscrição", {}), simple_url: "ranking-desfazer-spec"
    )
    @phase1 = add_phase(
      @process, 1, name: "Avaliação",
      consolidation_form: create_consolidation_template("Consolidação", { "Nota final" => code_field("0") })
    )
    @phase2 = add_phase(@process, 2, name: "Resultado")
    @ranking_config = FactoryBot.create(
      :ranking_config,
      name: "Bolsas",
      default_column: "Nota final",
      behavior_on_invalid_condition: Admissions::RankingConfig::EXCEPTION_ON_MACHINE,
      behavior_on_invalid_ranking: Admissions::RankingConfig::EXCEPTION_RANKING,
      form_condition: field_condition("Nota final", Admissions::FormCondition::NOT_NULL)
    )
    @ranking_config.ranking_columns.first.update!(order: Admissions::RankingColumn::DESC)
    @ranking_config.ranking_processes.first.update!(step: 1)
    # Na fase 2, o desfazer volta à fase 1 e apaga a consolidação dela
    @candidates = ["9", "8"].each_with_index.map do |grade, index|
      application = create_application(@process, name: "Candidato #{index}", admission_phase: @phase2)
      create_phase_result(
        application, @phase1, Admissions::AdmissionPhaseResult::CONSOLIDATION,
        fields: { "Nota final" => grade }
      )
      application
    end
  end

  def generate_ranking
    Admissions::AdmissionProcessRanking.create!(
      ranking_config: Admissions::RankingConfig.find(@ranking_config.id),
      admission_process: Admissions::AdmissionProcess.find(@process.id)
    ).generate_ranking
  end

  def positions
    @candidates.map do |candidate|
      Admissions::AdmissionApplication.find(candidate.id).fields_hash[
        "#{Admissions::RankingConfig::POSITION}/#{@ranking_config.name}"
      ]&.value
    end
  end

  it "tira a posição de quem teve a consolidação desfeita" do
    generate_ranking
    expect(positions).to eq(["1", "2"])

    Admissions::AdmissionApplication.find(@candidates[0].id).undo_consolidation
    generate_ranking

    expect(positions).to eq([nil, "1"])
  end

  it "aborta e mantém o resultado quando a precondição não exige a nota (controle)" do
    generate_ranking
    @ranking_config.update!(form_condition: nil)
    Admissions::AdmissionApplication.find(@candidates[0].id).undo_consolidation

    expect { generate_ranking }.to raise_error(Exceptions::MissingFieldException)
    expect(positions).to eq(["1", "2"])
  end
end

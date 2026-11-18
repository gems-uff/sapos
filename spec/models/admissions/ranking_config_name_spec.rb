# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O nome da configuração de ranking dá nome aos campos "Posição/<nome>" e
# "Seletor/<nome>", que condições, relatórios e fórmulas citam pelo nome.
RSpec.describe Admissions::RankingConfig, "nome como chave dos campos", type: :model do
  before(:each) do
    template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @process = create_closed_admission_process(template, simple_url: "ranking-name")
    @config = FactoryBot.create(:ranking_config, name: "Seleção", default_column: "nota")
    FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: @config, order: 1)
    @application = create_application(@process, fields: { "nota" => "9" })
    @process.rankings.first.generate_ranking
    @condition = Admissions::FormCondition.create!(
      mode: Admissions::FormCondition::CONDITION, field: "Posição/Seleção",
      condition: Admissions::FormCondition::LE, value: "10"
    )
  end

  def evaluate
    @application.reload.satisfies_condition(
      @condition.reload, fields: @application.fields_hash,
      should_raise: Admissions::FormCondition::RAISE_PHASE
    )
  end

  it "a condição sobre a posição vale para o classificado" do
    expect(@condition).to be_valid
    expect(evaluate).to be true
  end

  it "recusa uma segunda configuração com o mesmo nome", pending: "issue #759" do
    expect(FactoryBot.build(:ranking_config, name: "Seleção", default_column: "nota")).not_to be_valid
  end

  it "não renomeia a configuração deixando a condição sem campo", pending: "issue #759" do
    @config.update(name: "Seleção 2026")
    expect { evaluate }.not_to raise_error
  end
end

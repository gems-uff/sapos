# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::RankingConfig, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:ranking_columns).dependent(:destroy) }
  it { should have_many(:ranking_groups).dependent(:destroy) }
  it { should have_many(:ranking_processes).dependent(:destroy) }
  it { should have_many(:admission_process_rankings).dependent(:restrict_with_exception) }
  it { should have_many(:admission_ranking_results).dependent(:destroy) }
  it { should belong_to(:form_template).required(false) }
  it { should belong_to(:position_field).required(false) }
  it { should belong_to(:machine_field).required(false) }
  it { should belong_to(:form_condition).required(false) }

  before(:all) do
    @destroy_later = []
    @form_field = FactoryBot.create(:form_field, name: "Coluna")
    @ranking_machine = FactoryBot.create(:ranking_machine)
  end
  after(:all) do
    @form_field.delete
    @ranking_machine.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:ranking_config) do
    ranking_config = Admissions::RankingConfig.new(
      name: "Configuração de Ranking",
      behavior_on_invalid_condition: Admissions::RankingConfig::IGNORE_CONDITION,
      behavior_on_invalid_ranking: Admissions::RankingConfig::IGNORE_RANKING
    )
    ranking_config.ranking_columns.build(
      name: "Coluna",
      order: Admissions::RankingColumn::ASC
    )
    ranking_config.ranking_processes.build(
      ranking_machine: @ranking_machine
    )
    ranking_config
  end
  subject { ranking_config }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it "should validate presence of at least one ranking column" do
      ranking_config.ranking_columns.clear
      expect(ranking_config).not_to be_valid
      expect(ranking_config).to have_error(:too_short).with_parameters(count: 1).on :ranking_columns
    end
    it "should validate presence of at least one ranking process" do
      ranking_config.ranking_processes.clear
      expect(ranking_config).not_to be_valid
      expect(ranking_config).to have_error(:too_short).with_parameters(count: 1).on :ranking_processes
    end
    it { should validate_presence_of(:behavior_on_invalid_condition) }
    it { should validate_inclusion_of(:behavior_on_invalid_condition).in_array(Admissions::RankingConfig::BEHAVIOR_ON_INVALID_CONDITIONS) }
    it { should validate_presence_of(:behavior_on_invalid_ranking) }
    it { should validate_inclusion_of(:behavior_on_invalid_ranking).in_array(Admissions::RankingConfig::BEHAVIOR_ON_INVALID_RANKINGS) }
  end
  # ToDo: before_validation
  # ToDo: initialize_dup

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        ranking_config.name = "Ranking"
        expect(ranking_config.to_label).to eq("Ranking")
      end
    end
  end
end

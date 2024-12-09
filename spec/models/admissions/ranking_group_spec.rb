# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::RankingGroup, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:ranking_config).required(true) }

  before(:all) do
    @ranking_config = FactoryBot.create(:ranking_config)
  end
  after(:all) do
    @ranking_config.delete
  end
  let(:ranking_group) do
    Admissions::RankingGroup.new(
      ranking_config: @ranking_config,
      name: "AC",
      vacancies: 5
    )
  end
  subject { ranking_group }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        ranking_group.vacancies = 5
        ranking_group.name = "AC"
        expect(ranking_group.to_label).to eq("AC 5")
      end
    end
    describe "total_vacancies" do
      it "returns the correct total vacancies" do
        ranking_group.vacancies = 5
        expect(ranking_group.total_vacancies).to eq(5)
      end
      it "returns infinity if vacancies is nil" do
        ranking_group.vacancies = nil
        expect(ranking_group.total_vacancies).to eq(Float::INFINITY)
      end
    end
  end
end

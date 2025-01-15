# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::RankingProcess, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:ranking_config).required(true) }
  it { should belong_to(:ranking_machine).required(true) }

  before(:all) do
    @destroy_later = []
    @ranking_config = FactoryBot.create(:ranking_config)
    @ranking_machine = FactoryBot.create(:ranking_machine)
  end
  after(:all) do
    @ranking_config.delete
    @ranking_machine.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:ranking_process) do
    Admissions::RankingProcess.new(
      ranking_config: @ranking_config,
      ranking_machine: @ranking_machine,
    )
  end
  subject { ranking_process }
  describe "Validations" do
    it { should be_valid }
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        @ranking_machine.name = "Machine"
        ranking_process.vacancies = 5
        ranking_process.group = "AC"
        expect(ranking_process.to_label).to eq("Machine 5-AC")
      end
    end
    # ToDo: calculate_remaining
    # ToDo: decrease_vacancies_and_check_remaining!
  end
end

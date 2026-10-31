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
    it { should validate_presence_of(:step) }
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
    describe "decrease_vacancies!" do
      it "decreases the process and its group" do
        ranking_process.group = "AC"
        groups = { "AC" => 3 }
        process_vacancies = { ranking_process.id => 2 }
        ranking_process.decrease_vacancies!(groups, process_vacancies)
        expect(groups).to eq("AC" => 2)
        expect(process_vacancies).to eq(ranking_process.id => 1)
      end
    end
    describe "decrease_group!" do
      it "decreases only the group" do
        ranking_process.group = "AC"
        groups = { "AC" => 3 }
        ranking_process.decrease_group!(groups)
        expect(groups).to eq("AC" => 2)
      end
      it "leaves the groups alone when the process has no group" do
        groups = { "AC" => 3 }
        ranking_process.decrease_group!(groups)
        expect(groups).to eq("AC" => 3)
      end
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionProcessRanking, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:ranking_config).required(true) }
  it { should belong_to(:admission_process).required(true) }
  it { should belong_to(:admission_phase).required(false) }

  before(:all) do
    @ranking_config = FactoryBot.create(:ranking_config)
    @admission_process = FactoryBot.create(:admission_process)
    @admission_phase = FactoryBot.create(:admission_phase)
    @admission_process_phase = FactoryBot.create(:admission_process_phase, admission_process: @admission_process, admission_phase: @admission_phase)
  end
  after(:all) do
    @admission_process_phase.delete
    @admission_process.delete
    @admission_phase.delete
    @ranking_config.delete
  end
  let(:admission_process_ranking) do
    Admissions::AdmissionProcessRanking.new(
      ranking_config: @ranking_config,
      admission_process: @admission_process,
      admission_phase: @admission_phase
    )
  end
  subject { admission_process_ranking }
  describe "Validations" do
    it { should be_valid }
    context "that_phase_is_part_of_the_process" do
      it "should be valid if phase is part of the process" do
        admission_process_ranking.admission_phase = @admission_phase
        expect(admission_process_ranking).to be_valid
      end
      it "should have error if phase is not part of the process" do
        admission_process_ranking.admission_phase = FactoryBot.create(:admission_phase)
        expect(admission_process_ranking).to have_error(:phase_not_in_process).on(:admission_phase)
        admission_process_ranking.admission_phase = @admission_phase
      end
      it "should be valid if phase is nil" do
        admission_process_ranking.admission_phase = nil
        expect(admission_process_ranking).not_to have_error(:phase_not_in_process).on(:admission_phase)
      end
      it "should be valid if process is nil" do
        admission_process_ranking.admission_process = nil
        expect(admission_process_ranking).not_to have_error(:phase_not_in_process).on(:admission_phase)
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        @ranking_config.name = "Config"
        @admission_process.name = "Processo"
        @admission_process.year = 2024
        @admission_process.semester = 2
        expect(admission_process_ranking.to_label).to eq("Config - Processo (2024.2)")
      end
    end
    # ToDo: generate_ranking
    # ToDo: set_candidate_position
    # ToDo: filter_sort_candidates
    # ToDo: compare_candidates
  end

end

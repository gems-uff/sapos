# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionProcessPhase, type: :model do
  it { should be_able_to_be_destroyed }
  it { should belong_to(:admission_process).required(true) }
  it { should belong_to(:admission_phase).required(true) }

  before(:all) do
    @destroy_later = []
    @admission_process = FactoryBot.create(:admission_process)
    @admission_phase = FactoryBot.create(:admission_phase)
  end
  after(:all) do
    @admission_process.delete
    @admission_phase.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:admission_process_phase) do
    Admissions::AdmissionProcessPhase.new(
      admission_process: @admission_process,
      admission_phase: @admission_phase
    )
  end
  subject { admission_process_phase }
  describe "Validations" do
    it { should be_valid }
  end

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        @admission_process.name = "Processo"
        @admission_process.year = 2024
        @admission_process.semester = 2
        @admission_phase.name = "Fase"
        expect(admission_process_phase.to_label).to eq("Processo (2024.2) - Fase")
      end
    end
  end
end

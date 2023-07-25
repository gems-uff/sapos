# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe PhaseCompletion do
  let(:phase_completion) { PhaseCompletion.new }
  subject { deferral }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment_id is not null" do
          phase_completion.enrollment = FactoryBot.build(:enrollment)
          expect(phase_completion).to have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment_id is null" do
          phase_completion.enrollment = nil
          expect(phase_completion).to have_error(:blank).on :enrollment
        end
      end
    end
    describe "phase_id" do
      context "should be valid when" do
        it "phase_id is not null" do
          PhaseCompletion.destroy_all
          phase_completion.phase = FactoryBot.build(:phase)
          expect(phase_completion).to have(0).errors_on :phase
        end
      end
      context "should have error blank when" do
        it "phase_id is null" do
          phase_completion.phase = nil
          expect(phase_completion).to have_error(:blank).on :phase
        end
      end
    end

    describe "unique (phase_id, enrollment_id)" do
      context "should be valid when" do
        it "(phase_id, enrollment_id) is unique" do
          PhaseCompletion.destroy_all
          phase_completion.phase = FactoryBot.build(:phase)
          phase_completion.enrollment = FactoryBot.build(:enrollment)
          expect(phase_completion).to have(0).errors_on :phase
        end
      end
      context "should have error taken when" do
        it "(phase_id, enrollment_id) is not unique" do
          PhaseCompletion.destroy_all
          phase = FactoryBot.create(:phase)
          enrollment = FactoryBot.create(:enrollment)
          FactoryBot.create(:phase_completion, :phase => phase, :enrollment => enrollment)
          
          phase_completion.phase = phase
          phase_completion.enrollment = enrollment
          expect(phase_completion).to have_error(:taken).on :phase
        end
      end
    end
  end
end

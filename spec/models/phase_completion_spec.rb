# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhaseCompletion, type: :model do
  let(:phase) { FactoryBot.build(:phase) }
  let(:level) { FactoryBot.build(:level) }
  let(:enrollment) { FactoryBot.build(:enrollment, level: level) }

  let(:phase_completion) do
    PhaseCompletion.new(
      phase: phase,
      enrollment: enrollment
    )
  end
  subject { phase_completion }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:phase).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_uniqueness_of(:phase).scoped_to(:enrollment_id) }
  end

  describe "Methods" do
    before(:all) do
      @destroy_later = []
      @pc_level = FactoryBot.create(:level)
      @pc_phase = FactoryBot.create(:phase)
      @pc_enrollment_status = FactoryBot.create(:enrollment_status)
      @pc_student = FactoryBot.create(:student)
      @pc_enrollment = FactoryBot.create(:enrollment,
        level: @pc_level,
        enrollment_status: @pc_enrollment_status,
        student: @pc_student,
        admission_date: Date.new(2023, 1, 1)
      )
      @pc_phase_duration = FactoryBot.create(:phase_duration,
        phase: @pc_phase, level: @pc_level,
        deadline_semesters: 0, deadline_months: 1, deadline_days: 0
      )
      @pc_phase.reload
    end
    after(:all) do
      @destroy_later.each(&:delete)
      PhaseCompletion.where(enrollment_id: @pc_enrollment.id).delete_all
      @pc_phase_duration.delete
      @pc_enrollment.delete
      @pc_phase.delete
      @pc_student.delete
      @pc_enrollment_status.delete
      @pc_level.delete
    end
    after(:each) do
      @destroy_later.each(&:delete)
      @destroy_later.clear
    end

    describe "phase_accomplishment" do
      it "returns nil when there is no accomplishment for the phase" do
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: @pc_enrollment)
        expect(pc.phase_accomplishment).to be_nil
      end

      it "returns the accomplishment when it exists" do
        accomplishment = FactoryBot.create(:accomplishment,
          phase: @pc_phase, enrollment: @pc_enrollment,
          conclusion_date: Date.new(2023, 2, 15)
        )
        @destroy_later << accomplishment
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: @pc_enrollment)
        expect(pc.phase_accomplishment).to eq(accomplishment)
      end
    end

    describe "calculate_due_date" do
      it "sets due_date based on admission_date and phase duration" do
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: @pc_enrollment)
        expected_date = DateUtils.add_hash_to_date(
          @pc_enrollment.admission_date,
          @pc_phase.total_duration(@pc_enrollment)
        )
        expect(pc.due_date.to_date).to eq(expected_date)
      end

      it "does not set due_date when phase has no duration for the enrollment level" do
        other_level = FactoryBot.create(:level)
        other_student = FactoryBot.create(:student)
        other_enrollment = FactoryBot.create(:enrollment,
          level: other_level, admission_date: Date.new(2023, 1, 1),
          student: other_student
        )
        @destroy_later << other_enrollment
        @destroy_later << other_student
        @destroy_later << other_level
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: other_enrollment)
        pc.due_date = nil
        pc.calculate_due_date
        expect(pc.due_date).to be_nil
      end
    end

    describe "calculate_completion_date" do
      it "sets completion_date to nil when there is no accomplishment" do
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: @pc_enrollment)
        pc.completion_date = Date.today
        pc.calculate_completion_date
        expect(pc.completion_date).to be_nil
      end

      it "sets completion_date to the accomplishment conclusion_date" do
        conclusion_date = Date.new(2023, 2, 15)
        accomplishment = FactoryBot.create(:accomplishment,
          phase: @pc_phase, enrollment: @pc_enrollment,
          conclusion_date: conclusion_date
        )
        @destroy_later << accomplishment
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: @pc_enrollment)
        pc.calculate_completion_date
        expect(pc.completion_date.to_date).to eq(conclusion_date)
      end
    end

    describe "init" do
      it "does not calculate due_date when phase has no phase_durations" do
        empty_phase = FactoryBot.create(:phase)
        @destroy_later << empty_phase
        pc = PhaseCompletion.new(phase: empty_phase, enrollment: @pc_enrollment)
        expect(pc.due_date).to be_nil
      end

      it "calculates due_date when phase has phase_durations for enrollment level" do
        expected_date = DateUtils.add_hash_to_date(
          @pc_enrollment.admission_date,
          @pc_phase.total_duration(@pc_enrollment)
        )
        pc = PhaseCompletion.new(phase: @pc_phase, enrollment: @pc_enrollment)
        expect(pc.due_date.to_date).to eq(expected_date)
      end
    end
  end
end

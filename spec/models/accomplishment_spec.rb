# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Accomplishment, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
    @level = FactoryBot.create(:level)
    @phase = FactoryBot.build(:phase)
    @phase_duration = @phase.phase_durations.build(level: @level, deadline_semesters: 8)
    @phase.save
  end
  after(:all) do
    @level.delete
    @phase_duration.delete
    @phase.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:enrollment) { FactoryBot.build(:enrollment, level: @level) }
  let(:conclusion_date) { Date.today }
  let(:accomplishment) do
    Accomplishment.new(
      enrollment: enrollment,
      phase: @phase,
      conclusion_date: conclusion_date
    )
  end
  subject { accomplishment }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:enrollment).required(true) }
    it { should belong_to(:phase).required(true) }
    it { should validate_presence_of(:conclusion_date) }
    it { should accept_a_month_year_assignment_of(:conclusion_date, presence: true) }
    it do
      should validate_uniqueness_of(:enrollment).scoped_to(:phase_id)
                                                .with_message(:accomplishment_enrollment_uniqueness)
    end

    describe "enrollment" do
      context "should have error enrollment_level when" do
        it "phase phase does not have the enrollment level" do
          @destroy_later << another_level = FactoryBot.create(:level)
          accomplishment.enrollment.level = another_level
          expect(accomplishment).to have_error(:enrollment_level).on :enrollment
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        phase_name = "Accomplished Phase"
        accomplishment.phase.name = phase_name
        expect(accomplishment.to_label).to eql(phase_name)
      end
    end
  end
end

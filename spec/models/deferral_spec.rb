# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Deferral, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
    @level = FactoryBot.create(:level)
  end
  after(:all) do
    @level.delete
  end
  let(:phase) do
    phase = FactoryBot.build(:phase)
    phase.phase_durations.build(phase: phase, level: @level, deadline_semesters: 8)
    phase.save
    phase
  end
  after(:each) do
    phase.delete
  end
  let(:enrollment) { FactoryBot.create(:enrollment, level: @level) }
  let(:deferral_type) { FactoryBot.create(:deferral_type, phase: phase) }
  let(:approval_date) { Date.today }
  let(:deferral) do
    Deferral.new(
      enrollment: enrollment,
      deferral_type: deferral_type,
      approval_date: approval_date
    )
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
    phase.delete
    deferral_type.delete
    enrollment.delete
  end
  subject { deferral }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:enrollment).required(true) }
    it { should belong_to(:deferral_type).required(true) }
    it do
      should validate_uniqueness_of(:enrollment).scoped_to(:deferral_type_id)
                                                .with_message(:enrollment_and_deferral_uniqueness)
    end
    it { should validate_presence_of(:approval_date) }
    it { should accept_a_month_year_assignment_of(:approval_date, presence: true) }

    describe "enrollment" do
      context "should have error enrollment_level when" do
        it "deferral_type phase does not have the enrollment level" do
          @destroy_later << another_level = FactoryBot.create(:level)
          deferral.enrollment.level = another_level
          expect(deferral).to have_error(:enrollment_level).on :enrollment
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        deferral_type_name = "DeferralType"
        deferral_type.name = deferral_type_name
        expect(deferral.to_label).to eql(deferral_type_name)
      end
    end
    describe "valid_until" do
      it "should return 31th of july 2013" do
        enrollment.update!(admission_date: Date.new(2012, 3, 1))
        phase.phase_durations[0].update!(deadline_semesters: 1, deadline_days: 0)
        deferral_type.update!(duration_semesters: 2, duration_days: 0)
        @destroy_later << deferral if deferral.save
        expect(deferral.valid_until).to eql(Date.new(2013, 7, 31).strftime("%d/%m/%Y"))
      end
      it "should return 28th of february 2023" do
        enrollment.update!(admission_date: Date.new(2017, 8, 1))
        phase.phase_durations[0].update!(deadline_semesters: 8, deadline_days: 0)
        deferral_type.update!(duration_semesters: 3, duration_days: 0)
        @destroy_later << deferral if deferral.save
        expect(deferral.valid_until).to eql(Date.new(2023, 2, 28).strftime("%d/%m/%Y"))
      end
      it "should return 7th of june 2014" do
        enrollment.update!(admission_date: Date.new(2013, 8, 1))
        phase.phase_durations[0].update!(deadline_semesters: 1, deadline_days: 0)
        deferral_type.update!(duration_months: 3, duration_days: 7)
        @destroy_later << deferral if deferral.save
        expect(deferral.valid_until).to eql(Date.new(2014, 6, 7).strftime("%d/%m/%Y"))
      end
    end
  end
end

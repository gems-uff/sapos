# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhaseDuration, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
  end

  let(:level) { FactoryBot.build(:level) }
  let(:phase) { FactoryBot.build(:phase) }
  let(:deadline_semesters) { 8 }
  let(:phase_duration) do
    PhaseDuration.new(
      phase: phase,
      level: level,
      deadline_semesters: deadline_semesters
    )
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  subject { phase_duration }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:phase).required(true) }
    it { should belong_to(:level).required(true) }
    it { should validate_numericality_of(:deadline_semesters).only_integer }
    it { should validate_numericality_of(:deadline_months).only_integer }
    it { should validate_numericality_of(:deadline_days).only_integer }

    describe "deadline" do
      context "should have error blank_duration when" do
        it "equals 0" do
          phase_duration.deadline_days = 0
          phase_duration.deadline_months = 0
          phase_duration.deadline_semesters = nil
          expect(phase_duration).to have_error(:blank_deadline).on :base
        end
      end
    end

    describe "validate_destroy" do
      context "should be valid when" do
        it "there is no deferral nor accomplishment with the same phase and level as the phase_duration" do
          expect(phase_duration.send(:validate_destroy)).to eq(true)
          expect(phase_duration.phase).to have(0).errors_on :base
          expect(phase_duration).to have(0).errors_on :deadline
        end
      end
      context "should have error has_deferral when" do
        it "there is a deferral with the same level as the phase_duration" do
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << deferral_type = FactoryBot.create(:deferral_type, phase: phase)
          @destroy_later << FactoryBot.create(:deferral, enrollment: enrollment, deferral_type: deferral_type)

          expect(phase_duration.send(:validate_destroy)).to eq(false)
          expect(phase_duration.phase.errors.full_messages).to include(
            I18n.t("activerecord.errors.models.phase.phase_duration_has_deferral", level: level.to_label)
          )
          expect(phase_duration.errors.full_messages).to include(
            I18n.t("activerecord.errors.models.phase_duration.has_deferral")
          )
        end
      end
      context "should have error has_level when" do
        it "there is a deferral with the same level as the phase_duration" do
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << FactoryBot.create(:accomplishment, enrollment: enrollment, phase: phase)

          expect(phase_duration.send(:validate_destroy)).to eq(false)
          expect(phase_duration.phase.errors.full_messages).to include(
            I18n.t("activerecord.errors.models.phase.phase_duration_has_level", level: level.to_label)
          )
          expect(phase_duration.errors.full_messages).to include(
            I18n.t("activerecord.errors.models.phase_duration.has_level")
          )
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        deadline_semesters = 1
        deadline_months = 2
        deadline_days = 3
        phase_duration.deadline_semesters = deadline_semesters
        phase_duration.deadline_months = deadline_months
        phase_duration.deadline_days = deadline_days
        expected = "#{deadline_semesters} período, #{deadline_months} meses e #{deadline_days} dias"
        expect(phase_duration.to_label).to eql(expected)
      end
    end
    describe "duration" do
      it "should return a hash with the duration" do
        expect(phase_duration.duration).to eql({ semesters: deadline_semesters, months: 0, days: 0 })
      end
    end
  end
end

#encoding: UTF-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe PhaseDuration do
  let(:phase_duration) { PhaseDuration.new }
  subject { phase_duration }
  describe "Validations" do
    describe "phase" do
      context "should be valid when" do
        it "phase is not null" do
          phase_duration.phase = Phase.new
          expect(phase_duration).to have(0).errors_on :phase
        end
      end
      context "should have error blank when" do
        it "phase is null" do
          phase_duration.phase = nil
          expect(phase_duration).to have_error(:blank).on :phase
        end
      end
    end
    describe "level" do
      context "should be valid when" do
        it "level is not null" do
          phase_duration.level = Level.new
          expect(phase_duration).to have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          phase_duration.level = nil
          expect(phase_duration).to have_error(:blank).on :level
        end
      end
    end
    describe "deadline" do
      context "should be valid when" do
        it "is equal or greater than one day" do
          phase_duration.deadline_months = 0
          phase_duration.deadline_semesters = 0
          phase_duration.deadline_days = 1
          expect(phase_duration).to have(0).errors_on :deadline
        end
      end
      context "should have error blank_duration when" do
        it "equals 0" do
          phase_duration.deadline_days = 0
          phase_duration.deadline_months = 0
          phase_duration.deadline_semesters = nil
          expect(phase_duration).to have_error(:blank_deadline).on :deadline
        end
      end
    end
    describe "validate_destroy" do
      context "should be valid when" do
        it "there is no deferral with the same level and no accomplishment with the same phase and level as the phase_duration" do
          phase_duration = FactoryGirl.create(:phase_duration)
          expect(phase_duration.validate_destroy).to eq(true)
          expect(phase_duration.phase).to have(0).errors_on :base
          expect(phase_duration).to have(0).errors_on :deadline
        end
      end
      context "should have error has_deferral when" do
        it "there is a deferral with the same level as the phase_duration" do
          level = FactoryGirl.create(:level)
          phase = FactoryGirl.create(:phase)
          enrollment = FactoryGirl.create(:enrollment, :level => level)
          deferral_type = FactoryGirl.create(:deferral_type, :phase => phase)
          deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type)

          phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :level => level)
       
          expect(phase_duration.validate_destroy).to eq(false)
          expect(phase_duration.phase.errors.full_messages).to include(I18n.t('activerecord.errors.models.phase.phase_duration_has_deferral', :level => level.to_label))
          expect(phase_duration.errors.full_messages).to include(I18n.t('activerecord.errors.models.phase_duration.has_deferral'))
        end
      end
      context "should have error has_level when" do
        it "there is a deferral with the same level as the phase_duration" do
          level = FactoryGirl.create(:level)
          phase = FactoryGirl.create(:phase)
          enrollment = FactoryGirl.create(:enrollment, :level => level)
          phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :level => level)
          accomplishment = FactoryGirl.create(:accomplishment, :enrollment => enrollment, :phase => phase)

          expect(phase_duration.validate_destroy).to eq(false)
          expect(phase_duration.phase.errors.full_messages).to include(I18n.t('activerecord.errors.models.phase.phase_duration_has_level', :level => level.to_label))
          expect(phase_duration.errors.full_messages).to include(I18n.t('activerecord.errors.models.phase_duration.has_level'))
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
        expected = "#{deadline_semesters} períodos, #{deadline_months} meses e #{deadline_days} dias"
        expect(phase_duration.to_label).to eql(expected)
      end
    end
  end
end

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

    #-------------------------------------------------------------------------

    describe "deadline_semesters" do

      context "should be invalid when" do
  
        invalid_values = {'nil': nil, 'empty string': '', 'not numeric string': 'a', 'not integer string': '1.5', 'not integer': 1.5}

        invalid_values.each do |description, value| 
          it "is #{description}" do 
            phase_duration.deadline_semesters = value
            expect( phase_duration.errors_on(:deadline_semesters) ).not_to be_empty
          end
        end  
      end

      context "should be valid when" do
  
        valid_values = {'zero string': '0', 'positive integer string': '1', 'negative integer string': '-1', 'zero': 0, 'positive integer': 1, 'negative integer': -1}

        valid_values.each do |description, value| 
          it "is #{description}" do 
            phase_duration.deadline_semesters = value
            expect( phase_duration.errors_on(:deadline_semesters) ).to be_empty
          end
        end  
      end

    end

    #-------------------------------------------------------------------------

    describe "deadline_months" do

      context "should be invalid when" do
  
        invalid_values = {'nil': nil, 'empty string': '', 'not numeric string': 'a', 'not integer string': '1.5', 'not integer': 1.5}

        invalid_values.each do |description, value| 
          it "is #{description}" do 
            phase_duration.deadline_months = value
            expect( phase_duration.errors_on(:deadline_months) ).not_to be_empty
          end
        end  
      end

      context "should be valid when" do
  
        valid_values = {'zero string': '0', 'positive integer string': '1', 'negative integer string': '-1', 'zero': 0, 'positive integer': 1, 'negative integer': -1}

        valid_values.each do |description, value| 
          it "is #{description}" do 
            phase_duration.deadline_months = value
            expect( phase_duration.errors_on(:deadline_months) ).to be_empty
          end
        end  
      end

    end

    #-------------------------------------------------------------------------

    describe "deadline_days" do

      context "should be invalid when" do
  
        invalid_values = {'nil': nil, 'empty string': '', 'not numeric string': 'a', 'not integer string': '1.5', 'not integer': 1.5}

        invalid_values.each do |description, value| 
          it "is #{description}" do 
            phase_duration.deadline_days = value
            expect( phase_duration.errors_on(:deadline_days) ).not_to be_empty
          end
        end  
      end

      context "should be valid when" do
  
        valid_values = {'zero string': '0', 'positive integer string': '1', 'negative integer string': '-1', 'zero': 0, 'positive integer': 1, 'negative integer': -1}

        valid_values.each do |description, value| 
          it "is #{description}" do 
            phase_duration.deadline_days = value
            expect( phase_duration.errors_on(:deadline_days) ).to be_empty
          end
        end  
      end

    end

    #-------------------------------------------------------------------------

    describe "validate_destroy" do
      context "should be valid when" do
        it "there is no deferral with the same level and no accomplishment with the same phase and level as the phase_duration" do
          phase_duration = FactoryBot.create(:phase_duration)
          expect(phase_duration.validate_destroy).to eq(true)
          expect(phase_duration.phase).to have(0).errors_on :base
          expect(phase_duration).to have(0).errors_on :deadline
        end
      end
      context "should have error has_deferral when" do
        it "there is a deferral with the same level as the phase_duration" do
          level = FactoryBot.create(:level)
          phase = FactoryBot.create(:phase)
          enrollment = FactoryBot.create(:enrollment, :level => level)
          deferral_type = FactoryBot.create(:deferral_type, :phase => phase)
          deferral = FactoryBot.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type)

          phase_duration = FactoryBot.create(:phase_duration, :phase => phase, :level => level)
       
          expect(phase_duration.validate_destroy).to eq(false)
          expect(phase_duration.phase.errors.full_messages).to include(I18n.t('activerecord.errors.models.phase.phase_duration_has_deferral', :level => level.to_label))
          expect(phase_duration.errors.full_messages).to include(I18n.t('activerecord.errors.models.phase_duration.has_deferral'))
        end
      end
      context "should have error has_level when" do
        it "there is a deferral with the same level as the phase_duration" do
          level = FactoryBot.create(:level)
          phase = FactoryBot.create(:phase)
          enrollment = FactoryBot.create(:enrollment, :level => level)
          phase_duration = FactoryBot.create(:phase_duration, :phase => phase, :level => level)
          accomplishment = FactoryBot.create(:accomplishment, :enrollment => enrollment, :phase => phase)

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

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"


describe ScholarshipDuration do
  let(:scholarship_duration) { ScholarshipDuration.new }
  let(:start_date) { 3.days.ago.to_date }
  let(:end_date) { 3.days.from_now.to_date }
  subject { scholarship_duration }
  describe "Validations" do
    describe "scholarship" do
      context "should be valid when" do
        it "scholarship is not null" do
          scholarship_duration.scholarship = Scholarship.new
          expect(scholarship_duration).to have(0).errors_on :scholarship
        end
      end
    end
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null and scholarship is not with another student" do
          scholarship_duration.scholarship = FactoryGirl.create(:scholarship)
          scholarship_duration.enrollment = Enrollment.new
          expect(scholarship_duration).to have(0).errors_on :enrollment
        end
      end
      context "should have error taken when" do
        it "enrollment has other active scholarship" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date)

          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship, :start_date => start_date, :end_date => end_date)
          scholarship_duration.enrollment = enrollment
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = start_date
          scholarship_duration.end_date = end_date

          expect(scholarship_duration).to have_error(:enrollment_and_scholarship_uniqueness).on :enrollment_id
        end
      end
    end
    describe "start_date" do
      context "should be valid when" do
        it "is after scholarship start date" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date)
          scholarship_duration.enrollment = enrollment
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = start_date + 1.day
          scholarship_duration.end_date = end_date
          expect(scholarship_duration).to have(0).errors_on :start_date
        end
        it "is before scholarship end date" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date)
          scholarship_duration.enrollment = enrollment
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = end_date - 2.day
          scholarship_duration.end_date = end_date - 1.day
          expect(scholarship_duration).to have(0).errors_on :start_date
        end
      end
    end
    describe "end_date" do
      context "is valid and greater than scholarship.end_date" do
        it "there must be a cancel_date less than or equal scholarship.end_date" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date)
          scholarship_duration.enrollment = enrollment
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = scholarship.start_date
          scholarship_duration.end_date = scholarship.end_date + 1.day
          scholarship_duration.cancel_date = scholarship.end_date
          expect(scholarship_duration).to have(0).errors_on :end_date
        end
      end
    end
    describe "if_scholarship_is_not_with_another_student" do
      context "should return the expected error when" do
        it "has an old scholarship that ends after the new scholarship starts" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => start_date, :end_date => end_date + 2.days)
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.days
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration).to have_error(:start_date_before_scholarship_end_date).on :start_date
        end

        it "has an old scholarship that was canceled after the new scholarship starts" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => start_date, :end_date => end_date + 2.days, :cancel_date => end_date + 1.day)
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.days
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration).to have_error(:start_date_before_scholarship_cancel_date).on :start_date
        end
        it "has an new scholarship that starts before the scholarship ends" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => end_date, :end_date => end_date + 2.days)
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = start_date
          scholarship_duration.end_date = end_date + 1.day
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration).to have_error(:scholarship_start_date_after_end_or_cancel_date).on :end_date
        end

        it "has an new scholarship that is canceled before the scholarship ends" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => end_date, :end_date => end_date + 2.days)
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date = start_date
          scholarship_duration.end_date = end_date + 2.days
          scholarship_duration.cancel_date = end_date + 1.day
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration).to have_error(:scholarship_start_date_after_end_or_cancel_date).on :cancel_date
        end

      end
    end

  end
  describe "Methods" do
    describe "student_has_other_scholarship_duration" do
      context "should return true when" do
        it "has an old scholarship that ends after the new scholarship starts" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => start_date, :end_date => end_date + 2.days)
          scholarship_duration.scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 5.days)
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.days
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end
        it "has an old scholarship that was canceled after the new scholarship starts" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => start_date, :end_date => end_date + 2.days, :cancel_date => end_date + 1.day)
          scholarship_duration.scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 5.days)
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.days
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end
        it "has an new scholarship that starts before the scholarship ends" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => end_date, :end_date => end_date + 2.days)
          scholarship_duration.scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date + 1.day)
          scholarship_duration.start_date = start_date
          scholarship_duration.end_date = end_date + 1.day
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end

        it "has an new scholarship that is canceled before the scholarship ends" do
          enrollment = FactoryGirl.create(:enrollment)
          scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 2.days)
          FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                             :start_date => end_date, :end_date => end_date + 2.days)
          scholarship_duration.scholarship = FactoryGirl.create(:scholarship, :start_date => start_date, :end_date => end_date + 2.days)
          scholarship_duration.start_date = start_date
          scholarship_duration.end_date = end_date + 2.days
          scholarship_duration.cancel_date = end_date + 1.day
          scholarship_duration.enrollment = enrollment
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end
      end
    end
    describe "to_label" do
      it "should return the expected string" do
        scholarship_duration.start_date = start_date
        scholarship_duration.end_date = end_date
        expect(scholarship_duration.to_label).to eql("#{I18n.localize(start_date, :format => :monthyear)} - #{I18n.localize(end_date, :format => :monthyear)}")
      end
    end

    describe "warning_message" do
      it "should return nil when everything is alright" do
        enrollment = FactoryGirl.create(:enrollment)
        scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 5.days)
        FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                           :start_date => end_date, :end_date => end_date + 2.days, :cancel_date => end_date + 2.days)
        scholarship_duration.scholarship = scholarship
        scholarship_duration.start_date = end_date + 3.days
        scholarship_duration.end_date = end_date + 5.days
        #scholarship_duration.cancel_date = end_date + 1.day
        scholarship_duration.enrollment = enrollment
        expect(scholarship_duration.warning_message).to be_nil
      end

      it "should return unfinished scholarship warning when there is an unfinished scholarship" do
        enrollment = FactoryGirl.create(:enrollment)
        scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 5.days)
        FactoryGirl.create(:scholarship_duration, :enrollment => enrollment, :scholarship => scholarship,
                           :start_date => end_date, :end_date => end_date + 2.days)
        scholarship_duration.scholarship = scholarship
        scholarship_duration.start_date = end_date + 3.days
        scholarship_duration.end_date = end_date + 5.days
        #scholarship_duration.cancel_date = end_date + 1.day
        scholarship_duration.enrollment = enrollment
        expect(scholarship_duration.warning_message).to  eq(I18n.t("activerecord.errors.models.scholarship_duration.unfinished_scholarship"))
      end
    end

    describe 'last_date' do
      before(:all) do
        @scholarship = FactoryGirl.create(:scholarship, :start_date => 3.days.from_now.to_date, :end_date => 3.days.from_now.to_date + 5.months)
      end


      it 'should return end_date.end_of_month if there is no cancel_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => nil, :scholarship => @scholarship)
        expect(scholarship_duration.last_date).to eq((end_date + 2.months).end_of_month)
      end

      it 'should return cancel_date.end_of_month if there is a cancel_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => end_date + 1.months, :scholarship => @scholarship)
        expect(scholarship_duration.last_date).to eq((end_date + 1.months).end_of_month)
      end
    end

    describe 'was_cancelled?' do
      before(:all) do
        @scholarship = FactoryGirl.create(:scholarship, :start_date => 3.days.from_now.to_date, :end_date => 3.days.from_now.to_date + 5.months)
      end

      it 'should return false if there is no cancel_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => nil, :scholarship => @scholarship)
        expect(scholarship_duration.was_cancelled?).to eq(false)
      end

      it 'should return false if cancel_date == end_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => end_date + 2.months, :scholarship => @scholarship)
        expect(scholarship_duration.was_cancelled?).to eq(false)
      end

      it 'should return true if cancel_date != end_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => end_date + 1.months, :scholarship => @scholarship)
        expect(scholarship_duration.was_cancelled?).to eq(true)
      end      
    end
    describe 'active?' do
      before(:all) do
        @scholarship = FactoryGirl.create(:scholarship, :start_date => 3.days.from_now.to_date, :end_date => 3.days.from_now.to_date + 5.months)
      end

      it 'should return false if date is after end_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => nil, :scholarship => @scholarship)
        expect(scholarship_duration.active?(:date => end_date + 4.months)).to eq(false)
      end

      it 'should return false if date is in the month of cancel_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => end_date + 2.months, :scholarship => @scholarship)
        expect(scholarship_duration.active?(:date => scholarship_duration.cancel_date - 1.day)).to eq(false)
      end

      it 'should return false if date < start_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => end_date + 2.months, :scholarship => @scholarship)
        expect(scholarship_duration.active?(:date => end_date - 1.month)).to eq(false)
      end


      it 'should return true if date < cancel_date' do
        scholarship_duration = FactoryGirl.create(:scholarship_duration, :start_date => end_date, :end_date => end_date + 2.months, :cancel_date => end_date + 1.months, :scholarship => @scholarship)
        expect(scholarship_duration.active?(:date => end_date.end_of_month)).to eq(true)
      end      
    end
  end
end

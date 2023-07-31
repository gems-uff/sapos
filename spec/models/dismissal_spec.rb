# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dismissal, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:dismissal_reason) { FactoryBot.build(:dismissal_reason) }
  let(:enrollment) { FactoryBot.build(:enrollment) }
  let(:dismissal) do
    Dismissal.new(
      dismissal_reason: dismissal_reason,
      enrollment: enrollment,
      date: Date.today
    )
  end
  subject { dismissal }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:dismissal_reason).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_presence_of(:date) }

    describe "enrollment" do
      context "should be valid when" do
        it "enrollment has an ended scholarship" do
          @destroy_later << dismissal.enrollment = FactoryBot.create(:enrollment, admission_date: 2.months.ago.to_date)
          @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: 3.months.ago.to_date, end_date: 3.months.from_now.to_date)
          @destroy_later << FactoryBot.create(:scholarship_duration, start_date: 1.month.ago.to_date, end_date: 2.months.from_now.to_date, cancel_date: nil, scholarship: scholarship, enrollment: dismissal.enrollment)
          dismissal.date = 5.months.from_now.to_date
          expect(dismissal).to have(0).errors_on :enrollment
        end
      end
      context "should have error has_scholarship when" do
        it "enrollment has a valid scholarship during date" do
          @destroy_later << dismissal.enrollment = FactoryBot.create(:enrollment, admission_date: 2.months.ago.to_date)
          @destroy_later << scholarship = FactoryBot.create(:scholarship, start_date: 3.months.ago.to_date, end_date: 3.months.from_now.to_date)
          @destroy_later << FactoryBot.create(:scholarship_duration, start_date: 1.month.ago.to_date, end_date: 2.months.from_now.to_date, cancel_date: nil, scholarship: scholarship, enrollment: dismissal.enrollment)
          dismissal.date = 1.month.from_now.to_date
          expect(dismissal).not_to be_valid
          expect(dismissal.errors[:enrollment]).to include I18n.translate("activerecord.errors.models.dismissal.enrollment_has_scholarship")
        end
      end
    end
    describe "date" do
      context "should be valid when" do
        it "is after enrollment admission date" do
          @destroy_later << enrollment = FactoryBot.create(:enrollment, admission_date: 3.days.ago.to_date)
          dismissal.enrollment = enrollment
          dismissal.date = Date.today
          expect(dismissal).to have(0).errors_on :date
        end
      end
      context "should have error when" do
        it "is before enrollment admission date" do
          @destroy_later << enrollment = FactoryBot.create(:enrollment, admission_date: 3.days.ago.to_date)
          dismissal.enrollment = enrollment
          dismissal.date = 4.days.ago.to_date
          expect(dismissal).to have_error(:date_before_enrollment_admission_date).on :date
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        dismissal_date = "#{Date.today}"
        dismissal.date = dismissal_date
        expect(dismissal.to_label).to eql(dismissal_date)
      end
    end
  end
end

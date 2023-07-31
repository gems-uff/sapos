# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClassEnrollment, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_one(:class_enrollment_request).dependent(:nullify) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:course_class) { FactoryBot.build(:course_class) }
  let(:enrollment) { FactoryBot.build(:enrollment) }

  let(:class_enrollment) do
    ClassEnrollment.new(
      enrollment: enrollment,
      course_class: course_class,
      situation: I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
    )
  end
  subject { class_enrollment }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:course_class).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_uniqueness_of(:course_class).scoped_to(:enrollment_id) }
    it { should validate_inclusion_of(:situation).in_array([
      I18n.translate("activerecord.attributes.class_enrollment.situations.registered"),
      I18n.translate("activerecord.attributes.class_enrollment.situations.aproved"),
      I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
    ]) }
    it { should validate_presence_of(:situation) }

    describe "grade for situation" do
      context "should be valid when" do
        it "situation is registered and grade is nil" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
          class_enrollment.grade = nil
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have(0).errors_on :grade
        end
        it "situation is aproved and grade is greater than 59" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = 60
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have(0).errors_on :grade
        end
        it "situation is disapproved and grade is less than 60" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.grade = 59
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have(0).errors_on :grade
        end
        it "course does not have grade and grade is null" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = nil
          allow(class_enrollment).to receive(:course_has_grade).and_return(false)
          expect(class_enrollment).to have(0).errors_on :grade
        end
      end
      context "should have error grade_for_situation_registered when" do
        it "situation is registered and grade is not null" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
          class_enrollment.grade = 100
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_registered).on :grade
        end
      end
      context "should have error grade_for_situation_aproved when" do
        it "situation is aproved and grade is null" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = nil
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_aproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr(".", ",")
          ).on :grade
        end
        it "situation is aproved and grade is less than 60" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = 59
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_aproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr(".", ",")
          ).on :grade
        end
      end
      context "should have error grade_for_situation_disapproved when" do
        it "situation is disapproved and grade is null" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.grade = nil
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_disapproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr(".", ",")
          ).on :grade
        end
        it "situation is disapproved and grade is greater than 59" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.grade = 60
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_disapproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr(".", ",")
          ).on :grade
        end
      end
      context "should have error grade_filled_for_course_without_score when" do
        it "course does not have grade and grade is filled" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.grade = 59
          allow(class_enrollment).to receive(:course_has_grade).and_return(false)
          expect(class_enrollment).to have_error(:grade_filled_for_course_without_score).on :grade
        end
      end

      context "should have error grade_gt_100 when" do
        it "grade if greater than 100" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = 101
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_gt_100).on :grade
        end
      end

      context "should have error grade_lt_0 when" do
        it "grade if lower than 0" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = -1
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_lt_0).on :grade
        end
      end
    end
    describe "disapproved_by_absence for situation" do
      context "should be valid when" do
        it "situation is registered and disapproved_by_absence is false" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
          class_enrollment.disapproved_by_absence = false
          expect(class_enrollment).to have(0).errors_on :disapproved_by_absence
        end
        it "situation is aproved and disapproved_by_absence is false" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.disapproved_by_absence = false
          expect(class_enrollment).to have(0).errors_on :disapproved_by_absence
        end
        it "situation is disapproved and disapproved_by_absence is false" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.disapproved_by_absence = false
          expect(class_enrollment).to have(0).errors_on :disapproved_by_absence
        end
        it "situation is disapproved and disapproved_by_absence is true" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.disapproved_by_absence = true
          expect(class_enrollment).to have(0).errors_on :disapproved_by_absence
        end
      end
      context "should have error disapproved_by_absence_for_situation_registered when" do
        it "situation is registered and disapproved_by_absence is true" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
          class_enrollment.disapproved_by_absence = true
          expect(class_enrollment).to have_error(:disapproved_by_absence_for_situation_registered).on :disapproved_by_absence
        end
      end
      context "should have error disapproved_by_absence_for_situation_aproved when" do
        it "situation is aproved and grade is null" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.disapproved_by_absence = true
          expect(class_enrollment).to have_error(:disapproved_by_absence_for_situation_aproved).on :disapproved_by_absence
        end
      end
    end
  end
  describe "Methods" do
    describe "grade=" do
      context "parameter is a String number" do
        it "converts comma separated numbers" do
          class_enrollment.grade = "4,5"
          expect(class_enrollment.grade).to eq 45
        end
        it "converts dot separated numbers" do
          class_enrollment.grade = "6.3"
          expect(class_enrollment.grade).to eq 63
        end
      end
    end
    describe "grade_filled?" do
      context "should return true" do
        it "when grade is not null" do
          class_enrollment.grade = 10
          expect(class_enrollment.grade_filled?).to be_truthy
        end
      end
      context "should return false" do
        it "when grade is null" do
          class_enrollment.grade = nil
          expect(class_enrollment.grade_filled?).to be_falsey
        end
      end
    end

    describe "set_request_status_after_destroy" do
      it "should set the class enrollment request status to valid after destroy" do
        @destroy_later << course_class = FactoryBot.create(:course_class)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)
        @destroy_later << class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer = enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::EFFECTED,
          class_enrollment: class_enrollment
        )
        enrollment_request.save

        class_enrollment.destroy!
        cer.reload
        expect(cer.status).to eq(ClassEnrollmentRequest::INVALID)
      end
    end

    describe "class_enrollment_request_cascade" do
      it "should update course class of class enrollment request when course class of class enrollment changes" do
        @destroy_later << course_class = FactoryBot.create(:course_class)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)
        @destroy_later << class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer = enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::EFFECTED,
          class_enrollment: class_enrollment
        )
        enrollment_request.save
        @destroy_later << course_class2 = FactoryBot.create(:course_class)

        class_enrollment.course_class = course_class2
        class_enrollment.save
        cer.reload
        expect(cer.course_class).to eq(course_class2)
      end

      it "should disassociate class enrollment from request when enrollment changes" do
        @destroy_later << course_class = FactoryBot.create(:course_class)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)
        @destroy_later << class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer = enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::EFFECTED,
          class_enrollment: class_enrollment
        )
        enrollment_request.save
        @destroy_later << enrollment = FactoryBot.create(:enrollment)

        class_enrollment.enrollment = enrollment
        class_enrollment.save
        cer.reload
        expect(cer.class_enrollment).to eq(nil)
        expect(cer.status).to eq(ClassEnrollmentRequest::REQUESTED)
      end
    end
  end
end

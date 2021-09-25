# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe ClassEnrollment do
  let(:class_enrollment) { FactoryBot.build(:class_enrollment) }
  subject { class_enrollment }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          class_enrollment.enrollment = Enrollment.new
          expect(class_enrollment).to have(0).errors_on :enrollment 
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          class_enrollment.enrollment = nil
          expect(class_enrollment).to have_error(:blank).on :enrollment
        end
      end
    end
    describe "course_class" do
      context "should be valid when" do
        it "course_class is not null and is unique for the enrollment" do
          class_enrollment.course_class = CourseClass.new
          expect(class_enrollment).to have(0).errors_on :course_class
        end
      end
      context "should have error blank when" do
        it "course_class is null" do
          class_enrollment.course_class = nil
          expect(class_enrollment).to have_error(:blank).on :course_class
        end
      end
      context "should have error taken when" do
        it "course_class is already assigned for the same enrollment" do
          course_class = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => course_class)

          class_enrollment.course_class = course_class
          class_enrollment.enrollment = enrollment
          expect(class_enrollment).to have_error(:taken).on :course_class_id
        end
      end
    end
    describe "situation" do
      context "should be valid when" do
        it "situation is in the list" do
          class_enrollment.situation = ClassEnrollment::SITUATIONS.first
          expect(class_enrollment).to have(0).errors_on :situation
        end
      end
      context "should have error blank when" do
        it "situation is null" do
          class_enrollment.situation = nil
          expect(class_enrollment).to have_error(:blank).on :situation
        end
      end
      context "should have error inclusion when" do
        it "situation is not in the list" do
          class_enrollment.situation = "ANYTHING NOT IN THE LIST"
          expect(class_enrollment).to have_error(:inclusion).on :situation
        end
      end
    end
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
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr('.', ',')
          ).on :grade
        end
        it "situation is aproved and grade is less than 60" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          class_enrollment.grade = 59
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_aproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr('.', ',')
          ).on :grade
        end
      end
      context "should have error grade_for_situation_disapproved when" do
        it "situation is disapproved and grade is null" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.grade = nil
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_disapproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr('.', ',')
          ).on :grade
        end
        it "situation is disapproved and grade is greater than 59" do
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          class_enrollment.grade = 60
          allow(class_enrollment).to receive(:course_has_grade).and_return(true)
          expect(class_enrollment).to have_error(:grade_for_situation_disapproved).with_parameters(
            minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0).to_s.tr('.', ',')
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
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer = enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::EFFECTED,
          class_enrollment: class_enrollment
        )
        enrollment_request.save

        class_enrollment.destroy!
        cer.reload
        expect(cer.status).to eq(ClassEnrollmentRequest::VALID)
      end
    end

    describe "class_enrollment_request_cascade" do
      it "should update course class of class enrollment request when course class of class enrollment changes" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer = enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::EFFECTED,
          class_enrollment: class_enrollment
        )
        enrollment_request.save
        course_class2 = FactoryBot.create(:course_class)

        class_enrollment.course_class = course_class2
        class_enrollment.save
        cer.reload
        expect(cer.course_class).to eq(course_class2)
      end

      it "should disassociate class enrollment from request when enrollment changes" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer = enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::EFFECTED,
          class_enrollment: class_enrollment
        )
        enrollment_request.save
        enrollment = FactoryBot.create(:enrollment)

        class_enrollment.enrollment = enrollment
        class_enrollment.save
        cer.reload
        expect(cer.class_enrollment).to eq(nil)
        expect(cer.status).to eq(ClassEnrollmentRequest::REQUESTED)
      end
    end
  end
end


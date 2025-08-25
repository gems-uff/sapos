# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

def prepare_course_class(allocations, to_destroy, attributes = {})
  days = I18n.translate("date.day_names")
  to_destroy << cc = FactoryBot.create(:course_class, attributes)
  allocations.each do |day, start_time, end_time|
    to_destroy << FactoryBot.create(:allocation,  course_class: cc, day: days[day], start_time: start_time, end_time: end_time)
  end
  cc
end

RSpec.describe ClassEnrollmentRequest, type: :model do
  before(:all) do
    @destroy_later = []
    @level = FactoryBot.create(:level)
    @enrollment_status = FactoryBot.create(:enrollment_status)
    @student = FactoryBot.create(:student)
    @professor = FactoryBot.create(:professor)
    @course_type = FactoryBot.create(:course_type)
  end
  after(:all) do
    @course_type.delete
    @level.delete
    @enrollment_status.delete
    @professor.delete
    @student.delete
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  describe "Main Scenario" do
    before(:all) do
      @destroy_all = []
      @course = FactoryBot.create(:course, course_type: @course_type)
      @course_class = prepare_course_class([[0, 9, 11], [2, 9, 11]], @destroy_all, course: @course, professor: @professor)
      @enrollment = FactoryBot.create(
        :enrollment,
        level: @level,
        enrollment_status: @enrollment_status,
        student: @student
      )
    end
    after(:each) do
      @enrollment.reload
    end
    after(:all) do
      @destroy_all.each(&:delete)
      @course.delete
      @enrollment.delete
    end
    let(:enrollment_request) { FactoryBot.build(:enrollment_request, enrollment: @enrollment) }
    let(:class_enrollment_request) {
      enrollment_request.class_enrollment_requests.build(
        course_class: @course_class,
        status: ClassEnrollmentRequest::REQUESTED,
        action: ClassEnrollmentRequest::INSERT
      )
    }
    subject { class_enrollment_request }
    describe "Validations" do
      it { should be_valid }
      it { should validate_presence_of(:enrollment_request) }
      it { should validate_uniqueness_of(:course_class).scoped_to(:enrollment_request_id) }
      it { should validate_presence_of(:course_class) }
      it { should validate_inclusion_of(:status).in_array(ClassEnrollmentRequest::STATUSES) }
      it { should validate_presence_of(:status) }
      it { should validate_inclusion_of(:action).in_array(ClassEnrollmentRequest::ACTIONS) }
      it { should validate_presence_of(:action) }

      describe "course_class" do
        context "should be valid when" do
          it "course_class exists in a previous class_enrollment of the student, but its type allow multiple classes" do
            @course_type.update!(allow_multiple_classes: true)
            @destroy_later << class_enrollment = @enrollment.class_enrollments.create(
              course_class: @course_class,
              situation: ClassEnrollment::APPROVED
            )
            @enrollment.reload
            expect(class_enrollment).to be_valid

            expect(class_enrollment_request).to have(0).errors_on :course_class
          end
          it "course_class exists in a previous class_enrollment of the student, but the student was disapproved" do
            @course_type.update!(allow_multiple_classes: false)
            @destroy_later << @enrollment.class_enrollments.create(
              course_class: @course_class,
              situation: ClassEnrollment::DISAPPROVED
            )
            @enrollment.reload
            expect(class_enrollment_request).to have(0).errors_on :course_class
          end
        end
        context "should have error approved before when" do
          it "course_class exists in a previous class_enrollment of the student" do
            @course_type.update!(allow_multiple_classes: false)
            @destroy_later << @enrollment.class_enrollments.create(
              course_class: @course_class,
              situation: ClassEnrollment::APPROVED
            )
            @enrollment.reload
            expect(class_enrollment_request).to have_error(:previously_approved).on :course_class
          end
        end
      end
      describe "class_enrollment" do
        context "should be valid when" do
          it "class_enrollment is null, action is insert, and status is not effected" do
            class_enrollment_request.status = ClassEnrollmentRequest::REQUESTED
            class_enrollment_request.action = ClassEnrollmentRequest::INSERT
            class_enrollment_request.class_enrollment = nil
            expect(class_enrollment_request).to have(0).errors_on :class_enrollment
          end
          it "class_enrollment is filled, action is insert and status is effected" do
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            class_enrollment_request.action = ClassEnrollmentRequest::INSERT
            @destroy_later << class_enrollment_request.class_enrollment = FactoryBot.create(
              :class_enrollment, enrollment: @enrollment, course_class: @course_class)
            expect(class_enrollment_request).to have(0).errors_on :class_enrollment
          end
          it "class_enrollment is filled, action is remove, and status is not effected" do
            class_enrollment_request.status = ClassEnrollmentRequest::REQUESTED
            class_enrollment_request.action = ClassEnrollmentRequest::REMOVE
            @destroy_later << class_enrollment_request.class_enrollment = FactoryBot.create(
              :class_enrollment, enrollment: @enrollment, course_class: @course_class)
            expect(class_enrollment_request).to have(0).errors_on :class_enrollment
          end
          it "class_enrollment is null, action is remove, and status is effected" do
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            class_enrollment_request.action = ClassEnrollmentRequest::REMOVE
            class_enrollment_request.class_enrollment = nil
            expect(class_enrollment_request).to have(0).errors_on :class_enrollment
          end
        end
        context "should have error must_represent_the_same_enrollment_and_class when" do
          it "class_enrollment is associated to a different enrollment" do
            @destroy_later << enrollment_other = FactoryBot.create(:enrollment, student: @student, level: @level, enrollment_status: @enrollment_status)
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            @destroy_later << class_enrollment_request.class_enrollment = FactoryBot.create(
              :class_enrollment, enrollment: enrollment_other, course_class: @course_class)
            expect(class_enrollment_request).to have_error(
              :must_represent_the_same_enrollment_and_class).on :class_enrollment
          end
          it "class_enrollment is associated to a different course_class" do
            @destroy_later << course_class_other = FactoryBot.create(:course_class, professor: @professor)
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            @destroy_later << class_enrollment_request.class_enrollment = FactoryBot.create(
              :class_enrollment, enrollment: @enrollment, course_class: course_class_other)
            expect(class_enrollment_request).to have_error(
              :must_represent_the_same_enrollment_and_class).on :class_enrollment
          end
        end
        context "should have error enrollment_is_held when" do
          it "enrollment has an enrollment hold conflicting the date of course_class" do
            @destroy_later << e = FactoryBot.create(:enrollment, admission_date: 3.years.ago.at_beginning_of_month.to_date)
            @destroy_later << cc = FactoryBot.create(:course_class, year: 1.year.ago.year, semester: 1)
            @destroy_later << FactoryBot.create(:enrollment_hold, enrollment: e,
            year: 2.years.ago.year, number_of_semesters: 4)
            @destroy_later << cer = FactoryBot.create(:enrollment_request, enrollment: e)
            class_enrollment_request.enrollment_request = cer
            class_enrollment_request.course_class = cc
            expect(class_enrollment_request).to have_error(:enrollment_is_held).on :enrollment
          end
        end
      end
    end
    describe "Methods" do
      describe "create_or_destroy_class_enrollment" do
        it "should create a class enrollment when status is effected, class enrollment is blank, action is insert" do
          class_enrollment_request.class_enrollment = nil
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.action = ClassEnrollmentRequest::INSERT
          if class_enrollment_request.save
            @destroy_later << class_enrollment_request.class_enrollment
            @destroy_later << class_enrollment_request
          end
          expect(class_enrollment_request.class_enrollment).to be_present
        end
        it "should destroy a class enrollment when status is effected, class enrollment is blank, action is remove" do
          @destroy_later << class_enrollment_request.class_enrollment = FactoryBot.create(
            :class_enrollment, enrollment: @enrollment, course_class: @course_class)
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.action = ClassEnrollmentRequest::REMOVE
          if class_enrollment_request.save
            @destroy_later << class_enrollment_request
          end
          expect(class_enrollment_request.class_enrollment).not_to be_present
        end
      end
      describe "allocations" do
        it "should return an empty string when course class is nil" do
          class_enrollment_request.course_class = nil
          expect(class_enrollment_request.allocations).to eq("")
        end
        it "should return an empty string when course class does not have allocations" do
          class_enrollment_request.course_class = prepare_course_class([], @destroy_later, professor: @professor)
          expect(class_enrollment_request.allocations).to eq("")
        end
        it "should return a semicolon separated string when course class has allocations" do
          days = I18n.translate("date.day_names")
          class_enrollment_request.course_class = prepare_course_class([[0, 9, 11], [2, 14, 16]], @destroy_later, professor: @professor)
          expect(class_enrollment_request.allocations).to eq("#{days[0]} (9-11); #{days[2]} (14-16)")
        end
      end
      describe "professor" do
        it "should return nil when course class is nil" do
          class_enrollment_request.course_class = nil
          expect(class_enrollment_request.professor).to eq(nil)
        end
        it "should return nil when the professor of the course class is nil" do
          course_class = prepare_course_class([], @destroy_later, professor: @professor)
          course_class.professor = nil
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request.professor).to eq(nil)
        end
        it "should return the name of the professor of the course class" do
          professor = FactoryBot.build(:professor)
          course_class = prepare_course_class([], @destroy_later, professor: @professor)
          course_class.professor = professor
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request.professor).to eq(professor.to_label)
        end
      end
      describe "set_status!" do
        it "should build a class_enrollment and set the status to effected if there is no associated class_enrollment" do
          class_enrollment_request.status = ClassEnrollmentRequest::VALID
          class_enrollment_request.class_enrollment = nil
          expect(class_enrollment_request.set_status!(ClassEnrollmentRequest::EFFECTED)).to eq(true)
          expect(class_enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
          @destroy_later << class_enrollment_request
        end
        it "should set the status to effected if there is an associated class_enrollment" do
          class_enrollment = FactoryBot.build(:class_enrollment, enrollment: @enrollment, course_class: @course_class)
          class_enrollment_request.status = ClassEnrollmentRequest::VALID
          class_enrollment_request.class_enrollment = class_enrollment
          expect(class_enrollment_request.set_status!(ClassEnrollmentRequest::EFFECTED)).to eq(true)
          expect(class_enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
          @destroy_later << class_enrollment_request
        end
        it "should not change anything if it is already effected" do
          class_enrollment = FactoryBot.build(:class_enrollment, enrollment: @enrollment, course_class: @course_class)
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.class_enrollment = class_enrollment
          expect(class_enrollment_request.set_status!(ClassEnrollmentRequest::EFFECTED)).to eq(false)
          @destroy_later << class_enrollment_request
        end
      end
    end
  end
  describe "Scenario 2: filled database" do
    before(:all) do
      @destroy_later = []
      @destroy_all = []

      @destroy_all << enrollment = FactoryBot.create(:enrollment, student: @student, level: @level, enrollment_status: @enrollment_status)
      @destroy_all << course_effected = FactoryBot.create(:course, course_type: @course_type)
      @destroy_all << course_invalid = FactoryBot.create(:course, course_type: @course_type)
      @destroy_all << course_valid = FactoryBot.create(:course, course_type: @course_type)
      @destroy_all << course_class_effected = FactoryBot.create(:course_class, course: course_effected, professor: @professor)
      @destroy_all << course_class_invalid = FactoryBot.create(:course_class, course: course_invalid, professor: @professor)
      @destroy_all << course_class_valid = FactoryBot.create(:course_class, course: course_valid, professor: @professor)
      @destroy_all << class_enrollment = FactoryBot.create(
        :class_enrollment, enrollment: enrollment, course_class: course_class_effected)
      @destroy_all << enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
      @destroy_all << @effected = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::EFFECTED,
        course_class: course_class_effected,
        enrollment_request: enrollment_request,
        class_enrollment: class_enrollment
      )
      @destroy_all << @invalid = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::INVALID,
        course_class: course_class_invalid,
        enrollment_request: enrollment_request,
      )
      @destroy_all << @valid = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::VALID,
        course_class: course_class_valid,
        enrollment_request: enrollment_request,
      )
      @destroy_all << @requested = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::REQUESTED,
        course_class: course_class_valid,
        enrollment_request: enrollment_request,
      )
      enrollment_request.save
    end
    after(:all) do
      @destroy_all.each(&:delete)
    end
    after(:each) do
      @destroy_later.each(&:delete)
      @destroy_later.clear
    end
    describe "Class Methods" do
      describe "pendency_condition" do
        describe "should return a condition that returns valid and requested ClassEnrollmentRequests" do
          it "when user has a coordination role" do
            @destroy_later << role = FactoryBot.create(:role_coordenacao)
            @destroy_later << user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(2)
            expect(result).to include(@valid, @requested)
          end
          it "when user has a secretary role" do
            @destroy_later << role = FactoryBot.create(:role_secretaria)
            @destroy_later << user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(2)
            expect(result).to include(@valid, @requested)
          end
        end
        describe "should return a condition that does not return anything" do
          it "when user has an admin role" do
            @destroy_later << role = FactoryBot.create(:role_administrador)
            @destroy_later << user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(0)
          end
          it "when user has a professor role" do
            @destroy_later << role = FactoryBot.create(:role_professor)
            @destroy_later << user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(0)
          end
        end
      end
    end
  end
end

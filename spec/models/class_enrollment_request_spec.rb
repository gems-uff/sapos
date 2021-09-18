require 'spec_helper'

def prepare_course_class(allocations, attributes = {})
  days = I18n.translate("date.day_names")
  cc = FactoryBot.create(:course_class, attributes)
  allocations.each do |day, start_time, end_time|
    FactoryBot.create(:allocation,  course_class: cc, day: days[day], start_time: start_time, end_time: end_time)
  end
  cc
end

RSpec.describe ClassEnrollmentRequest, type: :model do
  
  describe "Main Scenario" do
    
    before(:all) do
      @course_type = FactoryBot.create(:course_type)
      @course = FactoryBot.create(:course, course_type: @course_type)
      @course_class = prepare_course_class([[0, 9, 11], [2, 9, 11]], course: @course)
    end
    let(:enrollment) { FactoryBot.create(:enrollment) }
    let(:enrollment_request) { FactoryBot.build(:enrollment_request, enrollment: enrollment) }
    let(:class_enrollment_request) { 
      enrollment_request.class_enrollment_requests.build(
        course_class: @course_class,
        status: ClassEnrollmentRequest::REQUESTED
      )
    }
    subject { class_enrollment_request }
    describe "Validations" do
      it { should be_valid }
      #it { should validate_presence_of?(:enrollment_request) }
      #it { should validate_presence_of?(:course_class) }
      #it { should validate_presence_of?(:status) }
      #it { should validate_inclusion_of?(:status).in_array(ClassEnrollmentRequest::STATUSES) }
      describe "enrollment_request" do
        context "should have error blank when" do
          it "enrollment_request is null" do
            class_enrollment_request.enrollment_request = nil
            expect(class_enrollment_request).to have_error(:blank).on :enrollment_request
          end
        end
      end
      describe "course_class" do
        context "should be valid when" do
          it "course_class exists in a previous class_enrollment of the student, but its type allow multiple classes" do
            @course_type.update!(allow_multiple_classes: true)
            class_enrollment = FactoryBot.create(
              :class_enrollment,
              enrollment: enrollment,
              course_class: @course_class,
              situation: ClassEnrollment::APPROVED
            )
            expect(class_enrollment).to be_valid

            expect(class_enrollment_request).to have(0).errors_on :course_class
          end
          it "course_class exists in a previous class_enrollment of the student, but the student was disapproved" do
            @course_type.update!(allow_multiple_classes: false)
            class_enrollment = FactoryBot.create(
              :class_enrollment,
              enrollment: enrollment,
              course_class: @course_class,
              situation: ClassEnrollment::DISAPPROVED
            )
            expect(class_enrollment_request).to have(0).errors_on :course_class
          end
          it "another course class in the request intersects an allocation in different days" do
            another_course_class = prepare_course_class([[1, 9, 11], [3, 9, 11]])
            enrollment_request.class_enrollment_requests.build(course_class: another_course_class)
            expect(class_enrollment_request).to have(0).errors_on :course_class
          end
        end
        context "should have error approved before when" do
          it "course_class exists in a previous class_enrollment of the student" do
            @course_type.update!(allow_multiple_classes: false)
            class_enrollment = FactoryBot.create(
              :class_enrollment,
              enrollment: enrollment,
              course_class: @course_class,
              situation: ClassEnrollment::APPROVED
            )
            expect(class_enrollment_request).to have_error(:previously_approved).on :course_class
          end
        end
        context "should have error taken when" do
          it "course_class exists in the request" do
            enrollment_request.class_enrollment_requests.build(course_class: @course_class)
            expect(class_enrollment_request).to have_error(:impossible_allocation).on :course_class
          end
        end
        context "should have error impossible allocation when" do
          it "another course class in the request intersects an allocation" do
            another_course_class = prepare_course_class([[0, 14, 16], [2, 8, 10]])
            enrollment_request.class_enrollment_requests.build(
              course_class: another_course_class
            )
            expect(class_enrollment_request).to have_error(:impossible_allocation).on :course_class
          end
          it "another course class in the request intersects an allocation through the other side" do
            another_course_class = prepare_course_class([[0, 14, 16], [2, 10, 12]])
            enrollment_request.class_enrollment_requests.build(
              course_class: another_course_class
            )
            expect(class_enrollment_request).to have_error(:impossible_allocation).on :course_class
          end
          it "another course class in the request has the same allocation" do
            another_course_class = prepare_course_class([[0, 9, 11], [2, 14, 16]])
            enrollment_request.class_enrollment_requests.build(
              course_class: another_course_class
            )
            expect(class_enrollment_request).to have_error(:impossible_allocation).on :course_class
          end
        end
      end
      describe "status" do
        context "should be valid when" do
          it "status is in the list" do
            class_enrollment_request.status = ClassEnrollmentRequest::STATUSES.first
            expect(class_enrollment_request).to have(0).errors_on :status
          end
        end
        context "should have error inclusion when" do
          it "status is not in the list" do
            class_enrollment_request.status = "ANYTHING NOT IN THE LIST"
            expect(class_enrollment_request).to have_error(:inclusion).on :status
          end
        end
      end
      describe "class_enrollment" do
        context "should be valid when" do
          it "class_enrollment is null and status is not effected" do
            class_enrollment_request.status = ClassEnrollmentRequest::REQUESTED
            class_enrollment_request.class_enrollment = nil
            expect(class_enrollment_request).to have(0).errors_on :class_enrollment
          end
          it "class_enrollment is filled and status is effected" do
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            class_enrollment_request.class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @course_class)
            expect(class_enrollment_request).to have(0).errors_on :class_enrollment
          end
        end
        context "should have error must_represent_the_same_enrollment_and_class when" do
          it "class_enrollment is associated to a different enrollment" do
            enrollment_other = FactoryBot.create(:enrollment)
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            class_enrollment_request.class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment_other, course_class: @course_class)
            expect(class_enrollment_request).to have_error(:must_represent_the_same_enrollment_and_class).on :class_enrollment
          end
          it "class_enrollment is associated to a different course_class" do
            course_class_other = FactoryBot.create(:course_class)
            class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
            class_enrollment_request.class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class_other)
            expect(class_enrollment_request).to have_error(:must_represent_the_same_enrollment_and_class).on :class_enrollment
          end
        end
      end
    end
    describe "Methods" do
      describe "create_class_enrollment" do
        it "should create a class enrollment when status is effected and class enrollment is blank" do
          class_enrollment_request.class_enrollment = nil
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.save
          expect(class_enrollment_request.class_enrollment).to be_present
        end
      end
      describe "allocations" do
        it "should return an empty string when course class is nil" do
          class_enrollment_request.course_class = nil
          expect(class_enrollment_request.allocations).to eq("")
        end
        it "should return an empty string when course class does not have allocations" do
          class_enrollment_request.course_class = prepare_course_class([])
          expect(class_enrollment_request.allocations).to eq("")
        end
        it "should return a semicolon separated string when course class has allocations" do
          days = I18n.translate("date.day_names")
          class_enrollment_request.course_class = prepare_course_class([[0, 9, 11], [2, 14, 16]])
          expect(class_enrollment_request.allocations).to eq("#{days[0]} (9-11); #{days[2]} (14-16)")
        end
      end
      describe "professor" do
        it "should return nil when course class is nil" do
          class_enrollment_request.course_class = nil
          expect(class_enrollment_request.professor).to eq(nil)
        end
        it "should return nil when the professor of the course class is nil" do
          course_class = prepare_course_class([])
          course_class.professor = nil
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request.professor).to eq(nil)
        end
        it "should return the name of the professor of the course class" do
          professor = FactoryBot.build(:professor)
          course_class = prepare_course_class([])
          course_class.professor = professor
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request.professor).to eq(professor.to_label)
        end
      end
      describe "parent_status" do
        it "should return nil when enrollment_request is nil" do
          class_enrollment_request.enrollment_request = nil
          expect(class_enrollment_request.parent_status).to eq(nil)
        end
        it "should return the status of the enrollment_request" do
          expect(class_enrollment_request.parent_status).to eq(ClassEnrollmentRequest::REQUESTED)
        end
      end
      describe "set_status!" do
        it "should build a class_enrollment and set the status to effected if there is no associated class_enrollment" do
          class_enrollment_request.status = ClassEnrollmentRequest::VALID
          class_enrollment_request.class_enrollment = nil
          expect(class_enrollment_request.set_status!(ClassEnrollmentRequest::EFFECTED)).to eq(true)
          expect(class_enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
          expect(class_enrollment_request.class_enrollment).not_to eq(nil)
          expect(class_enrollment_request.class_enrollment.enrollment).to eq(enrollment)
          expect(class_enrollment_request.class_enrollment.course_class).to eq(@course_class)
          expect(class_enrollment_request.class_enrollment.situation).to eq(ClassEnrollment::REGISTERED)
        end
        it "should set the status to effected if there is an associated class_enrollment" do
          class_enrollment = FactoryBot.build(:class_enrollment, enrollment: enrollment, course_class: @course_class)
          class_enrollment_request.status = ClassEnrollmentRequest::VALID
          class_enrollment_request.class_enrollment = class_enrollment
          expect(class_enrollment_request.set_status!(ClassEnrollmentRequest::EFFECTED)).to eq(true)
          expect(class_enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
          expect(class_enrollment_request.class_enrollment).to eq(class_enrollment)
        end
        it "should not change anything if it is already effected" do
          class_enrollment = FactoryBot.build(:class_enrollment, enrollment: enrollment, course_class: @course_class)
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.class_enrollment = class_enrollment
          expect(class_enrollment_request.set_status!(ClassEnrollmentRequest::EFFECTED)).to eq(false)
          expect(class_enrollment_request.class_enrollment).to eq(class_enrollment)
        end
      end
    end
  end
  describe "Scenario 2: filled database" do
    before(:all) do
      User.delete_all
      ClassEnrollmentRequest.delete_all
      EnrollmentRequest.delete_all
      ClassEnrollment.delete_all
      Dismissal.delete_all
      Enrollment.delete_all
      CourseClass.delete_all
      enrollment = FactoryBot.create(:enrollment)
      course_class_effected = FactoryBot.create(:course_class)
      course_class_invalid = FactoryBot.create(:course_class)
      course_class_valid = FactoryBot.create(:course_class)
      class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class_effected)
      enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
      @effected = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::EFFECTED,
        course_class: course_class_effected,
        enrollment_request: enrollment_request,
        class_enrollment: class_enrollment
      )
      @invalid = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::INVALID,
        course_class: course_class_invalid,
        enrollment_request: enrollment_request,
      )
      @valid = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::VALID,
        course_class: course_class_valid,
        enrollment_request: enrollment_request,
      )
      @requested = enrollment_request.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::REQUESTED,
        course_class: course_class_valid,
        enrollment_request: enrollment_request,
      )
      enrollment_request.save
    end
    after(:all) do
      User.delete_all
      ClassEnrollmentRequest.delete_all
      EnrollmentRequest.delete_all
      ClassEnrollment.delete_all
      Dismissal.delete_all
      Enrollment.delete_all
      CourseClass.delete_all
    end
    describe "Class Methods" do
      describe "pendency_condition" do
        describe "should return a condition that returns valid and requested ClassEnrollmentRequests" do
          it "when user has a coordination role" do
            role = FactoryBot.create(:role_coordenacao)
            user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(2)
            expect(result).to include(@valid, @requested)
          end
          it "when user has a secretary role" do
            role = FactoryBot.create(:role_secretaria)
            user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(2)
            expect(result).to include(@valid, @requested)
          end
        end
        describe "should return a condition that does not return anything" do
          it "when user has an admin role" do
            role = FactoryBot.create(:role_administrador)
            user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(0)
          end
          it "when user has a professor role" do
            role = FactoryBot.create(:role_professor)
            user = FactoryBot.create(:user, role: role)
            result = ClassEnrollmentRequest.where(ClassEnrollmentRequest.pendency_condition(user))
            expect(result.count).to eq(0)
          end
        end
      end
    end
  end
end

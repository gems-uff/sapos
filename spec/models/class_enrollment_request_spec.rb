require 'spec_helper'

def prepare_course_class(allocations)
  days = I18n.translate("date.day_names")
  cc = FactoryBot.create(:course_class)
  allocations.each do |day, start_time, end_time|
    FactoryBot.create(:allocation,  course_class: cc, day: days[day], start_time: start_time, end_time: end_time)
  end
  cc
end

RSpec.describe ClassEnrollmentRequest, type: :model do
  let(:class_enrollment_request) { ClassEnrollmentRequest.new }
  subject { class_enrollment_request }
  describe "Validations" do
    describe "enrollment_request" do
      context "should be valid when" do
        it "enrollment_request is not null" do
          class_enrollment_request.enrollment_request = EnrollmentRequest.new
          expect(class_enrollment_request).to have(0).errors_on :enrollment_request
        end
      end
      context "should have error blank when" do
        it "enrollment_request is null" do
          class_enrollment_request.enrollment_request = nil
          expect(class_enrollment_request).to have_error(:blank).on :enrollment_request
        end
      end
    end
    describe "course_class" do
      context "should be valid when" do
        it "course_class is not null" do
          class_enrollment_request.course_class = CourseClass.new
          expect(class_enrollment_request).to have(0).errors_on :course_class
        end
        it "course_class exists in a previous class_enrollment of the student, but its type allow multiple classes" do
          course_type = FactoryBot.create(:course_type, allow_multiple_classes: true)
          course = FactoryBot.create(:course, course_type: course_type)
          course_class = FactoryBot.create(:course_class, course: course)
          enrollment = FactoryBot.create(:enrollment)
          class_enrollment = FactoryBot.create(
            :class_enrollment,
            enrollment: enrollment,
            course_class: course_class,
            situation: ClassEnrollment::APPROVED
          )
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request).to have(0).errors_on :course_class
        end
        it "course_class exists in a previous class_enrollment of the student, but the student was disapproved" do
          course_type = FactoryBot.create(:course_type, allow_multiple_classes: false)
          course = FactoryBot.create(:course, course_type: course_type)
          course_class = FactoryBot.create(:course_class, course: course)
          enrollment = FactoryBot.create(:enrollment)
          class_enrollment = FactoryBot.create(
            :class_enrollment,
            enrollment: enrollment,
            course_class: course_class,
            situation: ClassEnrollment::DISAPPROVED
          )
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request).to have(0).errors_on :course_class
        end
        it "another course class in the request intersects an allocation in different days" do
          course_class1 = prepare_course_class([[0, 9, 11], [2, 9, 11]])
          course_class2 = prepare_course_class([[1, 9, 11], [3, 9, 11]])
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class1
          )
          enrollment_request.save

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class2
          expect(class_enrollment_request).to have(0).errors_on :course_class
        end
      end
      context "should have error blank when" do
        it "course_class is null" do
          class_enrollment_request.course_class = nil
          expect(class_enrollment_request).to have_error(:blank).on :course_class
        end
      end
      context "should have error approved before when" do
        it "course_class exists in a previous class_enrollment of the student" do
          course_type = FactoryBot.create(:course_type, allow_multiple_classes: false)
          course = FactoryBot.create(:course, course_type: course_type)
          course_class = FactoryBot.create(:course_class, course: course)
          enrollment = FactoryBot.create(:enrollment)
          class_enrollment = FactoryBot.create(
            :class_enrollment,
            enrollment: enrollment,
            course_class: course_class,
            situation: ClassEnrollment::APPROVED
          )
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request).to have_error(:previously_approved).on :course_class
        end
      end
      context "should have error taken when" do
        it "course_class exists in the request" do
          course_class = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class
          )
          enrollment_request.save

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class
          expect(class_enrollment_request.valid?).to eq(false)
          expect(class_enrollment_request.errors[:course_class]).to eq([I18n.t('activerecord.errors.models.class_enrollment_request.attributes.course_class.taken')])
        end
      end
      context "should have error impossible allocation when" do
        it "another course class in the request intersects an allocation" do
          course_class1 = prepare_course_class([[0, 9, 11], [2, 9, 11]])
          course_class2 = prepare_course_class([[0, 14, 16], [2, 8, 10]])
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class1
          )
          enrollment_request.save

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class2
          expect(class_enrollment_request).to have_error(:impossible_allocation).on :course_class
        end
        it "another course class in the request intersects an allocation through the other side" do
          course_class1 = prepare_course_class([[0, 9, 11], [2, 9, 11]])
          course_class2 = prepare_course_class([[0, 14, 16], [2, 10, 12]])
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class1
          )
          enrollment_request.save

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class2
          expect(class_enrollment_request).to have_error(:impossible_allocation).on :course_class
        end
        it "another course class in the request has the same allocation" do
          course_class1 = prepare_course_class([[0, 9, 11], [2, 9, 11]])
          course_class2 = prepare_course_class([[0, 9, 11], [2, 14, 16]])
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class1
          )
          enrollment_request.save

          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.course_class = course_class2
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
      context "should have error blank when" do
        it "status is null" do
          class_enrollment_request.status = nil
          expect(class_enrollment_request).to have_error(:blank).on :status
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
          course_class = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.course_class = course_class
          class_enrollment_request.class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class)
          expect(class_enrollment_request).to have(0).errors_on :class_enrollment
        end
      end
      context "should have error blank when" do
        it "class_enrollment is null and status is effected" do
          class_enrollment_request.class_enrollment = nil
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          expect(class_enrollment_request).to have_error(:blank).on :class_enrollment
        end
      end
      context "should have error must_represent_the_same_enrollment_and_class when" do
        it "class_enrollment is associated to a different enrollment" do
          course_class = FactoryBot.create(:course_class)
          enrollment_other = FactoryBot.create(:enrollment)
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.course_class = course_class
          class_enrollment_request.class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment_other, course_class: course_class)
          expect(class_enrollment_request).to have_error(:must_represent_the_same_enrollment_and_class).on :class_enrollment
        end
        it "class_enrollment is associated to a different course_class" do
          course_class = FactoryBot.create(:course_class)
          course_class_other = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
          class_enrollment_request.enrollment_request = enrollment_request
          class_enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          class_enrollment_request.course_class = course_class
          class_enrollment_request.class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class_other)
          expect(class_enrollment_request).to have_error(:must_represent_the_same_enrollment_and_class).on :class_enrollment
        end
      end
    end
  end
end

require "spec_helper"

describe ClassEnrollment do
  let(:class_enrollment) { ClassEnrollment.new }
  subject { class_enrollment }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          class_enrollment.enrollment = Enrollment.new
          class_enrollment.should have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          class_enrollment.enrollment = nil
          class_enrollment.should have_error(:blank).on :enrollment
        end
      end
    end
    describe "course_class" do
      context "should be valid when" do
        it "course_class is not null and is unique for the enrollment" do
          class_enrollment.course_class = CourseClass.new
          class_enrollment.should have(0).errors_on :course_class
        end
      end
      context "should have error blank when" do
        it "course_class is null" do
          class_enrollment.course_class = nil
          class_enrollment.should have_error(:blank).on :course_class
        end
      end
      context "should have error taken when" do
        it "course_class is already assigned for the same enrollment" do
          course_class =  FactoryGirl.create(:course_class)
          enrollment =  FactoryGirl.create(:enrollment)
          FactoryGirl.create(:class_enrollment, :enrollment => enrollment, :course_class => course_class)

          class_enrollment.course_class = course_class
          class_enrollment.enrollment = enrollment
          class_enrollment.should have_error(:taken).on :course_class_id
        end
      end
    end
    describe "situation" do
      context "should be valid when" do
        it "situation is in the list" do
          class_enrollment.situation = ClassEnrollment::SITUATIONS.first
          class_enrollment.should have(0).errors_on :situation
        end
      end
      context "should have error blank when" do
        it "situation is null" do
          class_enrollment.situation = nil
          class_enrollment.should have_error(:blank).on :situation
        end
      end
      context "should have error inclusion when" do
        it "situation is not in the list" do
          class_enrollment.situation = "ANYTHING NOT IN THE LIST"
          class_enrollment.should have_error(:inclusion).on :situation
        end
      end
    end
  end
  describe "Methods" do
    describe "grade_filled?" do
      context "should return true" do
        it "when grade is not null" do
          class_enrollment.grade = 10
          class_enrollment.grade_filled?.should be_true
        end
      end
      context "should return false" do
        it "when grade is null" do
          class_enrollment.grade = nil
          class_enrollment.grade_filled?.should be_false
        end
      end
    end
  end
end
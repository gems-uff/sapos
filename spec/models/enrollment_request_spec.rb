require 'spec_helper'

RSpec.describe EnrollmentRequest, type: :model do
  let(:enrollment_request) { EnrollmentRequest.new }
  subject { enrollment_request }
  describe "Validations" do
    describe "year" do
      context "should be valid when" do
        it "year is not null" do
          enrollment_request.year = 2021
          expect(enrollment_request).to have(0).errors_on :year
        end
      end
      context "should have error blank when" do
        it "year is null" do
          enrollment_request.year = nil
          expect(enrollment_request).to have_error(:blank).on :year
        end
      end
    end
    describe "semester" do
      context "should be valid when" do
        it "semester is in Semesters list" do
          enrollment_request.semester = YearSemester::SEMESTERS[0]
          expect(enrollment_request).to have(0).errors_on :semester
        end
      end
      context "should have error blank when" do
        it "semester is null" do
          enrollment_request.semester = nil
          expect(enrollment_request).to have_error(:blank).on :semester
        end
      end
      context "should have error inclusion when" do
        it "semester is not in the list" do
          enrollment_request.semester = 10
          expect(enrollment_request).to have_error(:inclusion).on :semester
        end
      end
    end
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          enrollment_request.enrollment = Enrollment.new
          expect(enrollment_request).to have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          enrollment_request.enrollment = nil
          expect(enrollment_request).to have_error(:blank).on :enrollment
        end
      end
      context "should have error taken when" do
        it "enrollment already exists for this year and semester" do
          course_class = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          previous = FactoryBot.build(:enrollment_request, enrollment: enrollment, year: 2021, semester: YearSemester::SEMESTERS[0])
          previous.class_enrollment_requests.build(
            course_class: course_class
          )
          previous.save

          enrollment_request.enrollment = enrollment
          enrollment_request.year = 2021
          enrollment_request.semester = YearSemester::SEMESTERS[0]
          expect(enrollment_request).to have_error(:taken).on :enrollment
        end
      end
    end
    describe "status" do
      context "should be valid when" do
        it "status is in the list" do
          enrollment_request.status = ClassEnrollmentRequest::STATUSES.first
          expect(enrollment_request).to have(0).errors_on :status
        end
      end
      context "should have error blank when" do
        it "status is null" do
          enrollment_request.status = nil
          expect(enrollment_request).to have_error(:blank).on :status
        end
      end
      context "should have error inclusion when" do
        it "status is not in the list" do
          enrollment_request.status = "ANYTHING NOT IN THE LIST"
          expect(enrollment_request).to have_error(:inclusion).on :status
        end
      end
      context "should have error class_enrollment_request_is_not_effected when" do
        it "status is effected, but class enrollment requests are not effected" do
          course_class = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request.enrollment = enrollment
          enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class,
            status: ClassEnrollmentRequest::VALID
          )
          expect(enrollment_request).to have_error(:class_enrollment_request_is_not_effected).on :status
        end
      end
    end
    describe "class_enrollment_requests" do
      context "should be valid when" do
        it "there is at least one class enrollment request" do
          course_class = FactoryBot.create(:course_class)
          enrollment = FactoryBot.create(:enrollment)
          enrollment_request.enrollment = enrollment
          enrollment_request.status = ClassEnrollmentRequest::VALID
          enrollment_request.class_enrollment_requests.build(
            course_class: course_class,
            status: ClassEnrollmentRequest::VALID
          )
          expect(enrollment_request).to have(0).errors_on :class_enrollment_requests
        end
      end
      context "should have error error at_least_one_class when" do
        it "class enrollment request is empty" do
          enrollment_request.class_enrollment_requests = []
          expect(enrollment_request).to have_error(:at_least_one_class).on :class_enrollment_requests
        end
      end
    end
  end
  describe "Methods" do
    describe "pendency_condition" do
      before(:all) do
        DatabaseCleaner.clean_with(:truncation)

        enrollment1 = FactoryBot.create(:enrollment)
        enrollment2 = FactoryBot.create(:enrollment)
        enrollment3 = FactoryBot.create(:enrollment)
        @advisor = FactoryBot.create(:professor)
        FactoryBot.create(:advisement, professor: @advisor, enrollment: enrollment3)
        course_class1 = FactoryBot.create(:course_class)
        course_class2 = FactoryBot.create(:course_class)
        @with_valid = FactoryBot.build(:enrollment_request, enrollment: enrollment1)
        @with_valid.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::VALID, course_class: course_class1
        )
        @with_valid.save

        @with_valid_and_requested = FactoryBot.build(:enrollment_request, enrollment: enrollment2)
        @with_valid_and_requested.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
        )
        @with_valid_and_requested.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::VALID, course_class: course_class2
        )
        @with_valid_and_requested.save

        @with_requested_and_advisor = FactoryBot.build(:enrollment_request, enrollment: enrollment3)
        @with_requested_and_advisor.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
        )
        @with_requested_and_advisor.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class2
        )
        @with_requested_and_advisor.save
      end
      after(:all) do
        DatabaseCleaner.clean_with(:truncation)
      end
      describe "should return a condition that returns EnrollmentRequests that have requestes ClassEnrollmentRequests" do
        it "when user has a coordination role" do
          role = FactoryBot.create(:role_coordenacao)
          user = FactoryBot.create(:user, role: role)
          result = EnrollmentRequest.where(EnrollmentRequest.pendency_condition(user))
          expect(result.count).to eq(2)
          expect(result).to include(@with_valid_and_requested, @with_requested_and_advisor)
        end
        it "when user has a secretary role" do
          role = FactoryBot.create(:role_secretaria)
          user = FactoryBot.create(:user, role: role)
          result = EnrollmentRequest.where(EnrollmentRequest.pendency_condition(user))
          expect(result.count).to eq(2)
          expect(result).to include(@with_valid_and_requested, @with_requested_and_advisor)
        end
        it "when user has a professor role and is the advisor" do
          role = FactoryBot.create(:role_professor)
          user = FactoryBot.create(:user, role: role, professor: @advisor)
          result = EnrollmentRequest.where(EnrollmentRequest.pendency_condition(user))
          expect(result.count).to eq(1)
          expect(result).to include(@with_requested_and_advisor)
        end
      end
      describe "should return a condition that does not return anything" do
        it "when user has an admin role" do
          role = FactoryBot.create(:role_administrador)
          user = FactoryBot.create(:user, role: role)
          result = EnrollmentRequest.where(EnrollmentRequest.pendency_condition(user))
          expect(result.count).to eq(0)
        end
        it "when user has a professor role that is not the advisor" do
          role = FactoryBot.create(:role_professor)
          user = FactoryBot.create(:user, role: role)
          result = EnrollmentRequest.where(EnrollmentRequest.pendency_condition(user))
          expect(result.count).to eq(0)
        end
      end
    end
    describe "last_student_read_time" do
      before(:each) do
        DatabaseCleaner.clean_with(:truncation)
      end
      it "should return the creation date if there is no student change nor view" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        enrollment_request.year = 2021
        enrollment_request.semester = 1
        enrollment_request.enrollment = enrollment
        enrollment_request.status = ClassEnrollmentRequest::REQUESTED
        enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::REQUESTED
        )
        enrollment_request.save
        expect(enrollment_request.last_student_read_time).to eq(enrollment_request.created_at)
      end
      it "should return the maximum time among created_at, last_student_change_at, student_view_at" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        enrollment_request.year = 2021
        enrollment_request.semester = 1
        enrollment_request.enrollment = enrollment
        enrollment_request.status = ClassEnrollmentRequest::REQUESTED
        enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::REQUESTED
        )
        enrollment_request.save
        enrollment_request.last_student_change_at = enrollment_request.created_at + 2.days
        enrollment_request.student_view_at = enrollment_request.created_at + 1.day
        expect(enrollment_request.last_student_read_time).to eq(enrollment_request.last_student_change_at)
      end
    end
    describe "last_staff_read_time" do
      before(:each) do
        DatabaseCleaner.clean_with(:truncation)
      end
      it "should return a time before creation date if there is no staff change" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        enrollment_request.year = 2021
        enrollment_request.semester = 1
        enrollment_request.enrollment = enrollment
        enrollment_request.status = ClassEnrollmentRequest::REQUESTED
        enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::REQUESTED
        )
        enrollment_request.save
        expect(enrollment_request.last_staff_read_time).to be < enrollment_request.created_at
      end
      it "should return the staff change date if there is a data" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        enrollment_request.year = 2021
        enrollment_request.semester = 1
        enrollment_request.enrollment = enrollment
        enrollment_request.status = ClassEnrollmentRequest::REQUESTED
        enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::REQUESTED
        )
        enrollment_request.save
        enrollment_request.last_staff_change_at = enrollment_request.created_at + 2.days
        expect(enrollment_request.last_staff_read_time).to eq(enrollment_request.last_staff_change_at)
      end
    end
    describe "student_unread_messages" do
      it "should return the number of comments posted after the last time the student read" do
        course_class = FactoryBot.create(:course_class)
        enrollment = FactoryBot.create(:enrollment)
        enrollment_request.year = 2021
        enrollment_request.semester = 1
        enrollment_request.enrollment = enrollment
        enrollment_request.status = ClassEnrollmentRequest::REQUESTED
        enrollment_request.class_enrollment_requests.build(
          course_class: course_class,
          status: ClassEnrollmentRequest::REQUESTED
        )
        enrollment_request.save

        role_student = FactoryBot.create(:role_aluno)
        role_professor = FactoryBot.create(:role_aluno)
        student = FactoryBot.create(:user, role: role_student)
        advisor = FactoryBot.create(:user, role: role_professor)

        enrollment_request.enrollment_request_comments.build(
          message: "a", user: student, updated_at: enrollment_request.created_at
        )
        enrollment_request.enrollment_request_comments.build(
          message: "b", user: advisor, updated_at: enrollment_request.created_at + 1.day
        )
        enrollment_request.enrollment_request_comments.build(
          message: "c", user: student, updated_at: enrollment_request.created_at + 3.days
        )
        enrollment_request.enrollment_request_comments.build(
          message: "d", user: advisor, updated_at: enrollment_request.created_at + 4.days
        )
        enrollment_request.last_student_change_at = enrollment_request.created_at + 2.days

        expect(enrollment_request.student_unread_messages(student)).to eq(1)
      end
    end
    describe "to_label" do
      it "should return the semester and the enrollment label" do
        enrollment = FactoryBot.create(:enrollment)
        enrollment_request.year = 2021
        enrollment_request.semester = 1
        enrollment_request.enrollment = enrollment
        expect(enrollment_request.to_label).to eq("[2021.1] #{enrollment.to_label}")
      end
    end
    describe "course_class_ids" do
      it "should return a list of class enrollment request ids" do
        DatabaseCleaner.clean_with(:truncation)
        enrollment = FactoryBot.create(:enrollment)
        course_class1 = FactoryBot.create(:course_class)
        course_class2 = FactoryBot.create(:course_class)

        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer1 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
        )
        cer2 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::VALID, course_class: course_class2
        )
        enrollment_request.save

        expect(enrollment_request.course_class_ids).to include(cer1.id, cer2.id)
      end
    end
    describe "assign_course_class_ids" do
      it "should not update anything if the course classes did not change" do
        enrollment = FactoryBot.create(:enrollment)
        course_class1 = FactoryBot.create(:course_class)
        course_class2 = FactoryBot.create(:course_class)

        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer1 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
        )
        cer2 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::VALID, course_class: course_class2
        )
        enrollment_request.save

        changed, remove_class_enrollments = enrollment_request.assign_course_class_ids([course_class1.id.to_s, course_class2.id.to_s])
        expect(changed).to eq(false)
        expect(remove_class_enrollments).to eq([])
        enrollment_request.save
        
        expect(enrollment_request.class_enrollment_requests.count).to eq(2)
        expect(enrollment_request.class_enrollment_requests).to include(cer1, cer2)
      end
      it "should remove class enrollment requests that are not in the list and it should create others that are" do
        enrollment = FactoryBot.create(:enrollment)
        course_class1 = FactoryBot.create(:course_class)
        course_class2 = FactoryBot.create(:course_class)
        course_class3 = FactoryBot.create(:course_class)

        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer1 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
        )
        cer2 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::VALID, course_class: course_class2
        )
        enrollment_request.save

        changed, remove_class_enrollments = enrollment_request.assign_course_class_ids([course_class1.id.to_s, course_class3.id.to_s])
        expect(changed).to eq(true)
        expect(remove_class_enrollments).to eq([])
        enrollment_request.save_request(remove_class_enrollments)
        
        expect(enrollment_request.class_enrollment_requests.count).to eq(2)
        expect(enrollment_request.class_enrollment_requests).to include(cer1)
        expect(enrollment_request.class_enrollment_requests).not_to include(cer2)
      end
      it "should remove effected class enrollment requests with their associated class enrollments" do
        enrollment = FactoryBot.create(:enrollment)
        course_class1 = FactoryBot.create(:course_class)
        course_class2 = FactoryBot.create(:course_class)
        course_class3 = FactoryBot.create(:course_class)
        class_enrollment = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class2)

        enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment)
        cer1 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
        )
        cer2 = enrollment_request.class_enrollment_requests.build(
          status: ClassEnrollmentRequest::EFFECTED, course_class: course_class2,
          class_enrollment: class_enrollment
        )
        enrollment_request.save

        changed, remove_class_enrollments = enrollment_request.assign_course_class_ids([course_class1.id.to_s, course_class3.id.to_s])
        expect(changed).to eq(true)
        expect(remove_class_enrollments).to eq([class_enrollment])
        enrollment_request.save_request(remove_class_enrollments)
        
        expect { class_enrollment.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(enrollment_request.class_enrollment_requests.count).to eq(2)
        expect(enrollment_request.class_enrollment_requests).to include(cer1)
        expect(enrollment_request.class_enrollment_requests).not_to include(cer2)
      end
    end
    describe "refresh_status!" do
      context "when status is effected" do
        before(:each) do
          enrollment = FactoryBot.create(:enrollment)
          course_class1 = FactoryBot.create(:course_class)
          course_class2 = FactoryBot.create(:course_class)
          class_enrollment1 = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class1)
          class_enrollment2 = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class2)

  
          @enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment, status: ClassEnrollmentRequest::EFFECTED)
          @cer1 = @enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::EFFECTED, course_class: course_class1, class_enrollment: class_enrollment1
          )
          @cer2 = @enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::EFFECTED, course_class: course_class2, class_enrollment: class_enrollment2
          )
          @enrollment_request.save
        end
        it "should stay effected if the statuses did not change" do
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
        end
        it "should change to requested if it is the status of the maximum priority" do
          @cer1.status = ClassEnrollmentRequest::REQUESTED
          @cer2.status = ClassEnrollmentRequest::INVALID
          @cer1.save
          @cer2.save
          @enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::REQUESTED)
        end
        it "should change to invalid if it is the status of the maximum priority" do
          @cer1.status = ClassEnrollmentRequest::VALID
          @cer2.status = ClassEnrollmentRequest::INVALID
          @cer1.save
          @cer2.save
          @enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::INVALID)
        end
        it "should change to valid if it is the status of the maximum priority" do
          @cer1.status = ClassEnrollmentRequest::VALID
          @cer2.status = ClassEnrollmentRequest::EFFECTED
          @cer1.save
          @cer2.save
          @enrollment_request.status = ClassEnrollmentRequest::EFFECTED
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::VALID)
        end
      end
      context "when status is not effected" do
        before(:each) do
          enrollment = FactoryBot.create(:enrollment)
          course_class1 = FactoryBot.create(:course_class)
          course_class2 = FactoryBot.create(:course_class)
          class_enrollment1 = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class1)
          class_enrollment2 = FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: course_class2)

  
          @enrollment_request = FactoryBot.build(:enrollment_request, enrollment: enrollment, status: ClassEnrollmentRequest::VALID)
          @cer1 = @enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::VALID, course_class: course_class1, class_enrollment: class_enrollment1
          )
          @cer2 = @enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::VALID, course_class: course_class2, class_enrollment: class_enrollment2
          )
          @enrollment_request.save
        end
        it "should stay the same status if the statuses did not change" do
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::VALID)
        end
        it "should stay the same status if the statuses did not change to effected" do
          @cer1.status = ClassEnrollmentRequest::INVALID
          @cer2.status = ClassEnrollmentRequest::INVALID
          @cer1.save
          @cer2.save
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::VALID)
        end
        it "should change to effected if all the statuses change to effected" do
          @cer1.status = ClassEnrollmentRequest::EFFECTED
          @cer2.status = ClassEnrollmentRequest::EFFECTED
          @cer1.save
          @cer2.save
          @enrollment_request.status = ClassEnrollmentRequest::VALID
          @enrollment_request.refresh_status!
          expect(@enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
        end
      end
    end
  end
end

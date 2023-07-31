# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

def prepare_course_class(allocations, to_destroy, attributes = {})
  days = I18n.translate("date.day_names")
  to_destroy << cc = FactoryBot.create(:course_class, attributes)
  allocations.each do |day, start_time, end_time|
    to_destroy << FactoryBot.create(:allocation, course_class: cc, day: days[day],
                                                 start_time: start_time, end_time: end_time)
  end
  cc
end

RSpec.describe EnrollmentRequest, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:class_enrollment_requests).dependent(:destroy).autosave(true) }
  it { should have_many(:course_classes).through(:class_enrollment_requests) }
  it { should have_many(:enrollment_request_comments).dependent(:destroy) }
  before(:all) do
    @destroy_later = []
    @level = FactoryBot.create(:level)
    @enrollment_status = FactoryBot.create(:enrollment_status)
    @student = FactoryBot.create(:student)
    @professor = FactoryBot.create(:professor)
    @course_type = FactoryBot.create(:course_type)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @course_type.delete
    @level.delete
    @enrollment_status.delete
    @professor.delete
    @student.delete
  end

  describe "Main Scenario" do
    before(:all) do
      @destroy_all = []
      @course = FactoryBot.create(:course, course_type: @course_type)
      @course_class = prepare_course_class([[0, 9, 11], [2, 9, 11]], @destroy_all, course: @course, professor: @professor)
    end
    after(:all) do
      @destroy_all.each(&:delete)
      @course.delete
    end
    let(:enrollment) { FactoryBot.build(:enrollment) }
    let(:enrollment_request) do
      EnrollmentRequest.new(
        year: 2021,
        semester: YearSemester::SEMESTERS[0],
        enrollment: enrollment
      )
    end
    subject { enrollment_request }
    before(:each) do
      @cer = enrollment_request.class_enrollment_requests.build(
        course_class: @course_class,
        status: ClassEnrollmentRequest::REQUESTED,
        action: ClassEnrollmentRequest::INSERT
      )
    end

    describe "Validations" do
      it { should be_valid }
      it { should belong_to(:enrollment).required(true) }
      it { should validate_presence_of(:year) }
      it { should validate_inclusion_of(:semester).in_array(YearSemester::SEMESTERS) }
      it { should validate_presence_of(:semester) }
      it { should validate_uniqueness_of(:enrollment).scoped_to(:year, :semester) }
      describe "that_there_is_at_least_one_class_enrollment_request_insert" do
        context "should add error at_least_on during saving when" do
          before(:each) do
            enrollment_request.student_saving = true
          end
          it "there are only removals" do
            @cer.action = ClassEnrollmentRequest::REMOVE
            expect(enrollment_request).to have_error(:at_least_one_class).on :class_enrollment_requests
          end
          it "there are no insertions" do
            enrollment_request.class_enrollment_requests = []
            expect(enrollment_request).to have_error(:at_least_one_class).on :class_enrollment_requests
          end
        end
        context "should not add errors when it is not saving and" do
          it "there are only removals" do
            @cer.action = ClassEnrollmentRequest::REMOVE
            expect(enrollment_request).to be_valid
          end
          it "there are no insertions" do
            enrollment_request.class_enrollment_requests = []
            expect(enrollment_request).to be_valid
          end
        end
      end
      describe "that_all_requests_are_valid" do
        it "should add error invalid_class when a class enrollrement request has an error" do
          @cer.status = "something wrong"
          enrollment_request.student_saving = true
          expect(enrollment_request).to have_error(:invalid_class).with_parameters(count: 1).on :base
        end
      end
      describe "that_valid_insertion_is_not_set_to_false" do
        it "should add error impossible_insertion when valid_insertion is set to false" do
          enrollment_request.valid_insertion = false
          enrollment_request.student_saving = true
          expect(enrollment_request).to have_error(:impossible_insertion).on :base
        end
      end
      describe "that_valid_removal_is_not_set_to_false" do
        it "should add error impossible_removal when valid_removal is set to false" do
          enrollment_request.valid_removal = false
          enrollment_request.student_saving = true
          expect(enrollment_request).to have_error(:impossible_removal).on :base
        end
      end
      describe "that_allocations_do_not_match" do
        it "should not add error impossible_allocation when allocations match in different dates" do
          another_course_class = prepare_course_class([[1, 9, 11], [3, 9, 11]], @destroy_later, professor: @professor)
          enrollment_request.class_enrollment_requests.build(course_class: another_course_class)
          enrollment_request.student_saving = true
          expect(enrollment_request).to be_valid
        end
        context "should add error impossible_allocation when" do
          it "another course class in the request intersects an allocation" do
            another_course_class = prepare_course_class([[0, 14, 16], [2, 8, 10]], @destroy_later, professor: @professor)
            enrollment_request.class_enrollment_requests.build(
              course_class: another_course_class
            )
            enrollment_request.student_saving = true
            expect(enrollment_request).to have_error(
              :impossible_allocation
            ).with_parameters(day: I18n.translate("date.day_names")[2], start: "8", end: "10").on :base
          end
          it "another course class in the request intersects an allocation through the other side" do
            another_course_class = prepare_course_class([[0, 14, 16], [2, 10, 12]], @destroy_later, professor: @professor)
            enrollment_request.class_enrollment_requests.build(
              course_class: another_course_class
            )
            enrollment_request.student_saving = true
            expect(enrollment_request).to have_error(
              :impossible_allocation
            ).with_parameters(day: I18n.translate("date.day_names")[2], start: "10", end: "12").on :base
          end
          it "another course class in the request has the same allocation" do
            another_course_class = prepare_course_class([[0, 9, 11], [2, 14, 16]], @destroy_later, professor: @professor)
            enrollment_request.class_enrollment_requests.build(
              course_class: another_course_class
            )
            enrollment_request.student_saving = true
            expect(enrollment_request).to have_error(
              :impossible_allocation
            ).with_parameters(day: I18n.translate("date.day_names")[0], start: "9", end: "11").on :base
          end
        end
      end
    end
    describe "Methods" do
      describe "to_label" do
        it "should return the semester and the enrollment label" do
          expect(enrollment_request.to_label).to eq("2021.1")
        end
      end
      describe "status" do
        before(:each) do
          @destroy_later << course2 = FactoryBot.create(:course_class, professor: @professor)
          @cer2 = enrollment_request.class_enrollment_requests.build(
            course_class: course2
          )
        end
        it "should set effected if all items are effected" do
          @cer.status = ClassEnrollmentRequest::EFFECTED
          @cer2.status = ClassEnrollmentRequest::EFFECTED
          expect(enrollment_request.status).to eq(ClassEnrollmentRequest::EFFECTED)
        end
        context "should set invalid if any item is invalid" do
          it "when the other is requested" do
            @cer.status = ClassEnrollmentRequest::REQUESTED
            @cer2.status = ClassEnrollmentRequest::INVALID
            expect(enrollment_request.status).to eq(ClassEnrollmentRequest::INVALID)
          end
          it "when the other is valid" do
            @cer.status = ClassEnrollmentRequest::VALID
            @cer2.status = ClassEnrollmentRequest::INVALID
            expect(enrollment_request.status).to eq(ClassEnrollmentRequest::INVALID)
          end
          it "when the other is effected" do
            @cer.status = ClassEnrollmentRequest::EFFECTED
            @cer2.status = ClassEnrollmentRequest::INVALID
            expect(enrollment_request.status).to eq(ClassEnrollmentRequest::INVALID)
          end
        end
        it "should change to valid if all items are either valid or effect" do
          @cer.status = ClassEnrollmentRequest::VALID
          @cer2.status = ClassEnrollmentRequest::EFFECTED
          expect(enrollment_request.status).to eq(ClassEnrollmentRequest::VALID)
        end
        it "should change to requested if some items are valid and other are requested" do
          @cer.status = ClassEnrollmentRequest::VALID
          @cer2.status = ClassEnrollmentRequest::REQUESTED
          expect(enrollment_request.status).to eq(ClassEnrollmentRequest::REQUESTED)
        end
      end
      describe "student_change!" do
        it "should update both the last_student_change_at and the student_view_at attributes" do
          time = Time.current
          enrollment_request.student_change!(time)
          expect(enrollment_request.last_student_change_at.to_s).to eq(time.to_s)
          expect(enrollment_request.student_view_at.to_s).to eq(time.to_s)
        end
      end
      describe "last_student_read_time" do
        it "should return the creation date if there is no student change nor view" do
          @destroy_later << enrollment_request if enrollment_request.save
          expect(enrollment_request.last_student_read_time).to eq(enrollment_request.created_at)
        end
        it "should return the maximum time among created_at, last_student_change_at, student_view_at" do
          @destroy_later << enrollment_request if enrollment_request.save
          enrollment_request.last_student_change_at = enrollment_request.created_at + 2.days
          enrollment_request.student_view_at = enrollment_request.created_at + 1.day
          expect(enrollment_request.last_student_read_time).to eq(enrollment_request.last_student_change_at)
        end
      end
      describe "last_staff_read_time" do
        it "should return a time before creation date if there is no staff change" do
          @destroy_later << enrollment_request if enrollment_request.save
          expect(enrollment_request.last_staff_read_time).to be < enrollment_request.created_at
        end
        it "should return the staff change date if there is a data" do
          @destroy_later << enrollment_request if enrollment_request.save
          enrollment_request.last_staff_change_at = enrollment_request.created_at + 2.days
          expect(enrollment_request.last_staff_read_time).to eq(enrollment_request.last_staff_change_at)
        end
      end
      describe "student_unread_messages" do
        it "should return the number of comments posted after the last time the student read" do
          @destroy_later << enrollment_request if enrollment_request.save

          role_student = FactoryBot.build(:role_aluno)
          role_professor = FactoryBot.build(:role_aluno)
          student = FactoryBot.build(:user, role: role_student)
          advisor = FactoryBot.build(:user, role: role_professor)

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
      describe "has_effected_class_enrollment?" do
        context "should return true when" do
          it "has effected insertions" do
            @cer.status = ClassEnrollmentRequest::EFFECTED
            expect(enrollment_request.has_effected_class_enrollment?).to be_truthy
          end
          it "has non effected removals" do
            @cer.status = ClassEnrollmentRequest::REQUESTED
            @cer.action = ClassEnrollmentRequest::REMOVE
            expect(enrollment_request.has_effected_class_enrollment?).to be_truthy
          end
        end
        context "should return false when" do
          it "all insertions are not effected" do
            @cer.status = ClassEnrollmentRequest::REQUESTED
            expect(enrollment_request.has_effected_class_enrollment?).to be_falsey
          end
          it "all removals are effected" do
            @cer.status = ClassEnrollmentRequest::EFFECTED
            @cer.action = ClassEnrollmentRequest::REMOVE
            expect(enrollment_request.has_effected_class_enrollment?).to be_falsey
          end
        end
      end
      describe "course_class_ids" do
        it "should return a list of insertion class enrollment request ids" do
          @destroy_later << course_class = FactoryBot.create(:course_class, professor: @professor)
          another_cer = enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::VALID, course_class: course_class, action: ClassEnrollmentRequest::INSERT
          )
          expect(enrollment_request.save).to be_truthy
          @destroy_later << enrollment_request
          @destroy_later << @cer

          expect(enrollment_request.course_class_ids.count).to eq(2)
          expect(enrollment_request.course_class_ids).to include(@cer.course_class_id, another_cer.course_class_id)
        end
        it "should not return removal class enrollment request ids in the list" do
          @destroy_later << course_class = FactoryBot.create(:course_class, professor: @professor)
          another_cer = enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::VALID, course_class: course_class, action: ClassEnrollmentRequest::REMOVE
          )
          expect(enrollment_request.save).to be_truthy
          @destroy_later << enrollment_request
          @destroy_later << @cer

          expect(enrollment_request.course_class_ids.count).to eq(1)
          expect(enrollment_request.course_class_ids).to include(@cer.course_class_id)
          expect(enrollment_request.course_class_ids).not_to include(another_cer.course_class_id)
        end
      end
      describe "assign_course_class_ids and save_request" do
        before(:each) do
          @destroy_later << @course_class2 = FactoryBot.create(:course_class, professor: @professor)
          @destroy_later << @course_class3 = FactoryBot.create(:course_class, professor: @professor)
          @destroy_later << @cer2 = enrollment_request.class_enrollment_requests.build(
            status: ClassEnrollmentRequest::VALID, course_class: @course_class2, action: ClassEnrollmentRequest::INSERT
          )
          expect(enrollment_request.save).to be_truthy
          @destroy_later << enrollment_request
        end
        it "should not update anything if the course classes did not change" do
          request_change = enrollment_request.assign_course_class_ids([@course_class.id.to_s, @course_class2.id.to_s])
          expect(request_change[:new_removal_requests]).to eq([])
          expect(request_change[:new_insertion_requests]).to eq([])
          expect(request_change[:remove_removal_requests]).to eq([])
          expect(request_change[:remove_insertion_requests]).to eq([])
          expect(request_change[:existing_removal_requests]).to eq([])
          expect(request_change[:existing_insertion_requests]).to eq([@cer, @cer2])
          expect(request_change[:no_action]).to eq([])
          enrollment_request.save_request

          expect(enrollment_request.class_enrollment_requests.count).to eq(2)
          expect(enrollment_request.class_enrollment_requests).to include(@cer, @cer2)
        end
        it "should remove non effected insertions that are not in the list and insert new ones that are not" do
          request_change = enrollment_request.assign_course_class_ids([@course_class.id.to_s, @course_class3.id.to_s])
          expect(request_change[:new_removal_requests]).to eq([])
          expect(request_change[:new_insertion_requests].count).to eq(1)
          expect(request_change[:remove_removal_requests]).to eq([])
          expect(request_change[:remove_insertion_requests]).to eq([@cer2])
          expect(request_change[:existing_removal_requests]).to eq([])
          expect(request_change[:existing_insertion_requests]).to eq([@cer])
          expect(request_change[:no_action]).to eq([])
          enrollment_request.save_request

          expect(enrollment_request.class_enrollment_requests.count).to eq(2)
          expect(enrollment_request.class_enrollment_requests).to include(@cer)
          expect(enrollment_request.class_enrollment_requests).not_to include(@cer2)
        end
        it "should turn effected insertions into requested removals when they are not in the list" do
          @cer2.status = ClassEnrollmentRequest::EFFECTED

          request_change = enrollment_request.assign_course_class_ids([@course_class.id.to_s, @course_class3.id.to_s])
          expect(request_change[:new_removal_requests]).to eq([@cer2])
          expect(request_change[:new_insertion_requests].count).to eq(1)
          expect(request_change[:remove_removal_requests]).to eq([])
          expect(request_change[:remove_insertion_requests]).to eq([])
          expect(request_change[:existing_removal_requests]).to eq([])
          expect(request_change[:existing_insertion_requests]).to eq([@cer])
          expect(request_change[:no_action]).to eq([])
          enrollment_request.save_request

          expect(enrollment_request.class_enrollment_requests.count).to eq(3)
          expect(enrollment_request.class_enrollment_requests).to include(@cer, @cer2)
          expect(@cer2.action).to eq(ClassEnrollmentRequest::REMOVE)
          expect(@cer2.status).to eq(ClassEnrollmentRequest::REQUESTED)
        end
        it "should not update anything if removed requests did not change" do
          @cer.action = ClassEnrollmentRequest::REMOVE
          @cer2.action = ClassEnrollmentRequest::REMOVE
          request_change = enrollment_request.assign_course_class_ids([])
          expect(request_change[:new_removal_requests]).to eq([])
          expect(request_change[:new_insertion_requests]).to eq([])
          expect(request_change[:remove_removal_requests]).to eq([])
          expect(request_change[:remove_insertion_requests]).to eq([])
          expect(request_change[:existing_removal_requests]).to eq([@cer, @cer2])
          expect(request_change[:existing_insertion_requests]).to eq([])
          expect(request_change[:no_action]).to eq([])
          enrollment_request.save_request

          expect(enrollment_request.class_enrollment_requests.count).to eq(2)
          expect(enrollment_request.class_enrollment_requests).to include(@cer, @cer2)
        end
        it "should turn non effected removals that are in the list into effected insertions" do
          @cer.action = ClassEnrollmentRequest::REMOVE
          request_change = enrollment_request.assign_course_class_ids([@course_class.id.to_s])
          expect(request_change[:new_removal_requests]).to eq([])
          expect(request_change[:new_insertion_requests]).to eq([])
          expect(request_change[:remove_removal_requests]).to eq([@cer])
          expect(request_change[:remove_insertion_requests]).to eq([@cer2])
          expect(request_change[:existing_removal_requests]).to eq([])
          expect(request_change[:existing_insertion_requests]).to eq([])
          expect(request_change[:no_action]).to eq([])
          enrollment_request.save_request

          expect(enrollment_request.class_enrollment_requests.count).to eq(1)
          expect(enrollment_request.class_enrollment_requests).to include(@cer)
          expect(enrollment_request.class_enrollment_requests).not_to include(@cer2)
          expect(@cer.action).to eq(ClassEnrollmentRequest::INSERT)
          expect(@cer.status).to eq(ClassEnrollmentRequest::EFFECTED)
        end
        it "should turn effected removals that are in the list into requested insertions" do
          @cer.action = ClassEnrollmentRequest::REMOVE
          @cer.status = ClassEnrollmentRequest::EFFECTED
          request_change = enrollment_request.assign_course_class_ids([@course_class.id.to_s])
          expect(request_change[:new_removal_requests]).to eq([])
          expect(request_change[:new_insertion_requests]).to eq([@cer])
          expect(request_change[:remove_removal_requests]).to eq([])
          expect(request_change[:remove_insertion_requests]).to eq([@cer2])
          expect(request_change[:existing_removal_requests]).to eq([])
          expect(request_change[:existing_insertion_requests]).to eq([])
          expect(request_change[:no_action]).to eq([])
          enrollment_request.save_request

          expect(enrollment_request.class_enrollment_requests.count).to eq(1)
          expect(enrollment_request.class_enrollment_requests).to include(@cer)
          expect(enrollment_request.class_enrollment_requests).not_to include(@cer2)
          expect(@cer.action).to eq(ClassEnrollmentRequest::INSERT)
          expect(@cer.status).to eq(ClassEnrollmentRequest::REQUESTED)
        end
        context "class schedule restrictions" do
          before(:each) do
            @destroy_later << @course_class4 = FactoryBot.create(:course_class, professor: @professor)
            @destroy_later << @course_class5 = FactoryBot.create(:course_class, professor: @professor)
            @destroy_later << @course_class6 = FactoryBot.create(:course_class, professor: @professor)
            @destroy_later << @course_class7 = FactoryBot.create(:course_class, professor: @professor)
            @destroy_later << @course_class8 = FactoryBot.create(:course_class, professor: @professor)
            @destroy_later << @course_class9 = FactoryBot.create(:course_class, professor: @professor)
            @destroy_later << @cer3 = enrollment_request.class_enrollment_requests.build(
              status: ClassEnrollmentRequest::EFFECTED, course_class: @course_class3,
              action: ClassEnrollmentRequest::INSERT
            )
            @destroy_later << @cer4 = enrollment_request.class_enrollment_requests.build(
              status: ClassEnrollmentRequest::EFFECTED, course_class: @course_class4,
              action: ClassEnrollmentRequest::INSERT
            )
            @destroy_later << @cer5 = enrollment_request.class_enrollment_requests.build(
              status: ClassEnrollmentRequest::REQUESTED, course_class: @course_class5,
              action: ClassEnrollmentRequest::REMOVE
            )
            @destroy_later << @cer6 = enrollment_request.class_enrollment_requests.build(
              status: ClassEnrollmentRequest::REQUESTED, course_class: @course_class6,
              action: ClassEnrollmentRequest::REMOVE
            )
            @destroy_later << @cer7 = enrollment_request.class_enrollment_requests.build(
              status: ClassEnrollmentRequest::EFFECTED, course_class: @course_class7,
              action: ClassEnrollmentRequest::REMOVE
            )
            @destroy_later << @cer8 = enrollment_request.class_enrollment_requests.build(
              status: ClassEnrollmentRequest::EFFECTED, course_class: @course_class8,
              action: ClassEnrollmentRequest::REMOVE
            )
            expect(enrollment_request.save).to be_truthy
          end
          it "should work properly with the class schedule enrollment time" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 1.day,
              enrollment_end: now + 1.day,
              enrollment_adjust: now - 5.days,
              enrollment_insert: now - 4.days,
              enrollment_remove: now - 4.days,
            )
            request_change = enrollment_request.assign_course_class_ids([
              @course_class.id.to_s, @course_class3.id.to_s,
              @course_class5.id.to_s, @course_class7.id.to_s,
              @course_class9.id.to_s,
            ], class_schedule)
            expect(request_change[:new_removal_requests]).to eq([@cer4])
            expect(request_change[:new_insertion_requests].count).to eq(2)
            expect(request_change[:new_insertion_requests]).to include(@cer7)
            expect(request_change[:remove_removal_requests]).to eq([@cer5])
            expect(request_change[:remove_insertion_requests]).to eq([@cer2])
            expect(request_change[:existing_removal_requests]).to eq([@cer6])
            expect(request_change[:existing_insertion_requests]).to include(@cer, @cer3)
            expect(request_change[:no_action]).to eq([@cer8])
            enrollment_request.save_request

            expect(enrollment_request.class_enrollment_requests.count).to eq(8)
            expect(enrollment_request.class_enrollment_requests).to include(
              @cer, @cer3, @cer4, @cer5, @cer6, @cer7, @cer8
            )
            expect(enrollment_request.class_enrollment_requests).not_to include(@cer2)
          end
          it "should work properly within the class schedule adjustment time" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 1.day,
              enrollment_insert: now + 1.day,
              enrollment_remove: now + 1.day,
            )
            request_change = enrollment_request.assign_course_class_ids([
              @course_class.id.to_s, @course_class3.id.to_s,
              @course_class5.id.to_s, @course_class7.id.to_s,
              @course_class9.id.to_s,
            ], class_schedule)
            expect(request_change[:new_removal_requests]).to eq([@cer4])
            expect(request_change[:new_insertion_requests].count).to eq(2)
            expect(request_change[:new_insertion_requests]).to include(@cer7)
            expect(request_change[:remove_removal_requests]).to eq([@cer5])
            expect(request_change[:remove_insertion_requests]).to eq([@cer2])
            expect(request_change[:existing_removal_requests]).to eq([@cer6])
            expect(request_change[:existing_insertion_requests]).to include(@cer, @cer3)
            expect(request_change[:no_action]).to eq([@cer8])
            enrollment_request.save_request

            expect(enrollment_request.class_enrollment_requests.count).to eq(8)
            expect(enrollment_request.class_enrollment_requests).to include(
              @cer, @cer3, @cer4, @cer5, @cer6, @cer7, @cer8
            )
            expect(enrollment_request.class_enrollment_requests).not_to include(@cer2)
          end
          it "should not update anything if the enrollment time is not open in the class schedule" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 5.days,
              enrollment_insert: now - 4.days,
              enrollment_remove: now - 4.days,
            )
            request_change = enrollment_request.assign_course_class_ids([
              @course_class.id.to_s, @course_class3.id.to_s,
              @course_class5.id.to_s, @course_class7.id.to_s,
              @course_class9.id.to_s,
            ], class_schedule)
            expect(request_change[:new_removal_requests]).to eq([])
            expect(request_change[:new_insertion_requests]).to eq([])
            expect(request_change[:remove_removal_requests]).to eq([])
            expect(request_change[:remove_insertion_requests]).to eq([])
            expect(request_change[:existing_removal_requests]).to include(@cer5, @cer6)
            expect(request_change[:existing_insertion_requests]).to include(@cer, @cer2, @cer3, @cer4)
            expect(request_change[:no_action]).to include(@cer7, @cer8)
            enrollment_request.save_request

            expect(enrollment_request).to have_error(:impossible_insertion).on :base
            expect(enrollment_request).to have_error(:impossible_removal).on :base
            expect(enrollment_request.class_enrollment_requests.count).to eq(8)
            expect(enrollment_request.class_enrollment_requests).to include(
              @cer, @cer2, @cer3, @cer4, @cer5, @cer6, @cer7, @cer8
            )
          end
          it "should not remove anything if the enrollment time is open only for insertions" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 1.day,
              enrollment_insert: now + 1.day,
              enrollment_remove: now - 4.days,
            )
            request_change = enrollment_request.assign_course_class_ids([
              @course_class.id.to_s, @course_class3.id.to_s,
              @course_class5.id.to_s, @course_class7.id.to_s,
              @course_class9.id.to_s,
            ], class_schedule)
            expect(request_change[:new_removal_requests]).to eq([])
            expect(request_change[:new_insertion_requests].count).to eq(2)
            expect(request_change[:new_insertion_requests]).to include(@cer7)
            expect(request_change[:remove_removal_requests]).to eq([@cer5])
            expect(request_change[:remove_insertion_requests]).to eq([@cer2])
            expect(request_change[:existing_removal_requests]).to include(@cer6)
            expect(request_change[:existing_insertion_requests]).to include(@cer, @cer3, @cer4)
            expect(request_change[:no_action]).to eq([@cer8])

            enrollment_request.save_request
            expect(enrollment_request.class_enrollment_requests).to include(
              @cer, @cer2, @cer3, @cer4, @cer5, @cer6, @cer7, @cer8
            )
            expect(enrollment_request).to have_error(:impossible_removal).on :base
          end
          it "should not insert anything if the enrollment time is open only for removals" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 1.day,
              enrollment_insert: now - 4.days,
              enrollment_remove: now + 1.day,
            )
            request_change = enrollment_request.assign_course_class_ids([
              @course_class.id.to_s, @course_class3.id.to_s,
              @course_class5.id.to_s, @course_class7.id.to_s,
              @course_class9.id.to_s,
            ], class_schedule)
            expect(request_change[:new_removal_requests]).to eq([@cer4])
            expect(request_change[:new_insertion_requests]).to eq([])
            expect(request_change[:remove_removal_requests]).to eq([@cer5])
            expect(request_change[:remove_insertion_requests]).to eq([@cer2])
            expect(request_change[:existing_removal_requests]).to eq([@cer6])
            expect(request_change[:existing_insertion_requests]).to include(@cer, @cer3)
            expect(request_change[:no_action]).to include(@cer7, @cer8)
            enrollment_request.save_request

            expect(enrollment_request.class_enrollment_requests.count).to eq(8)
            expect(enrollment_request.class_enrollment_requests).to include(
              @cer, @cer2, @cer3, @cer4, @cer5, @cer6, @cer7, @cer8
            )
            expect(enrollment_request).to have_error(:impossible_insertion).on :base
          end
        end
      end
      describe "valid_destroy?" do
        context "should return true when" do
          it "the enrollment schedule is open" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 1.day,
              enrollment_end: now + 1.day,
              enrollment_adjust: now - 5.days,
              enrollment_insert: now - 4.days,
              enrollment_remove: now - 4.days,
            )
            expect(enrollment_request.valid_destroy?(class_schedule)).to be_truthy
          end
          it "the enrollment schedule is not open for removals, but there are no effected insertions" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 1.day,
              enrollment_insert: now + 1.day,
              enrollment_remove: now - 4.days,
            )
            expect(enrollment_request.valid_destroy?(class_schedule)).to be_truthy
          end
        end
        context "should return false when" do
          it "the enrollment schedule is not open" do
            now = Time.now
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 5.days,
              enrollment_insert: now - 4.days,
              enrollment_remove: now - 4.days,
            )
            expect(enrollment_request.valid_destroy?(class_schedule)).to be_falsey
          end
          it "the enrollment schedule is not open for removals, but there are effected insertions" do
            now = Time.now
            @cer.status = ClassEnrollmentRequest::EFFECTED
            class_schedule = FactoryBot.build(
              :class_schedule,
              enrollment_start: now - 5.days,
              enrollment_end: now - 4.days,
              enrollment_adjust: now - 1.day,
              enrollment_insert: now + 1.day,
              enrollment_remove: now - 4.days,
            )
            expect(enrollment_request.valid_destroy?(class_schedule)).to be_falsey
          end
        end
      end
      describe "destroy_request" do
        context "should not destroy the request when" do
          it "there are requested removals" do
            @cer.status = ClassEnrollmentRequest::REQUESTED
            @cer.action = ClassEnrollmentRequest::REMOVE
            expect(enrollment_request.destroy_request).to be_truthy
            expect { enrollment_request.reload }.not_to raise_error
          end
          it "there are effected insertions and it should transform them into requested removals" do
            @cer.status = ClassEnrollmentRequest::EFFECTED
            @cer.action = ClassEnrollmentRequest::INSERT
            expect(enrollment_request.destroy_request).to be_truthy
            expect { enrollment_request.reload }.not_to raise_error
            expect(@cer.status).to eq(ClassEnrollmentRequest::REQUESTED)
            expect(@cer.action).to eq(ClassEnrollmentRequest::REMOVE)
          end
        end
        context "should destroy the request when" do
          it "all requests are non effected insertions" do
            expect(enrollment_request.destroy_request).to be_truthy
            expect { enrollment_request.reload }.to raise_error ActiveRecord::RecordNotFound
          end
          it "all requests are effected removals" do
            @cer.status = ClassEnrollmentRequest::EFFECTED
            @cer.action = ClassEnrollmentRequest::REMOVE
            expect(enrollment_request.destroy_request).to be_truthy
            expect { enrollment_request.reload }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end
    end
  end

  describe "Scenario 2: filled database" do
    before(:all) do
      @destroy_scenario = []
      @destroy_scenario << enrollment1 = FactoryBot.create(:enrollment, student: @student, level: @level, enrollment_status: @enrollment_status)
      @destroy_scenario << enrollment2 = FactoryBot.create(:enrollment, student: @student, level: @level, enrollment_status: @enrollment_status)
      @destroy_scenario << enrollment3 = FactoryBot.create(:enrollment, student: @student, level: @level, enrollment_status: @enrollment_status)
      @destroy_scenario << @advisor = FactoryBot.create(:professor)
      @destroy_scenario << FactoryBot.create(:advisement, professor: @advisor, enrollment: enrollment3)
      @destroy_scenario << course1 = FactoryBot.create(:course, course_type: @course_type)
      @destroy_scenario << course2 = FactoryBot.create(:course, course_type: @course_type)
      @destroy_scenario << course_class1 = FactoryBot.create(:course_class, course: course1, professor: @professor)
      @destroy_scenario << course_class2 = FactoryBot.create(:course_class, course: course2, professor: @professor)
      @destroy_scenario << @with_valid = FactoryBot.build(:enrollment_request, enrollment: enrollment1)
      @destroy_scenario << @with_valid.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::VALID, course_class: course_class1
      )
      @with_valid.save

      @destroy_scenario << @with_valid_and_requested = FactoryBot.build(:enrollment_request, enrollment: enrollment2)
      @destroy_scenario << @with_valid_and_requested.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
      )
      @destroy_scenario << @with_valid_and_requested.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::VALID, course_class: course_class2
      )
      @with_valid_and_requested.save

      @destroy_scenario << @with_requested_and_advisor = FactoryBot.build(:enrollment_request, enrollment: enrollment3)
      @destroy_scenario << @with_requested_and_advisor.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::REQUESTED, course_class: course_class1
      )
      @destroy_scenario << @with_requested_and_advisor.class_enrollment_requests.build(
        status: ClassEnrollmentRequest::REQUESTED, course_class: course_class2
      )
      @with_requested_and_advisor.save
    end
    after(:all) do
      @destroy_scenario.each(&:delete)
    end
    describe "Class Methods" do
      describe "pendency_condition" do
        describe "should return a condition that returns EnrollmentRequests that have requestes ClassEnrollmentRequests" do
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
    end
  end
end

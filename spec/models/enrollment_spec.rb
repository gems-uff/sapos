# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Enrollment, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_one(:dismissal).dependent(:restrict_with_exception) }
  it { should have_many(:advisements).dependent(:destroy) }
  it { should have_many(:professors).through(:advisements) }
  it { should have_many(:scholarship_durations).dependent(:destroy) }
  it { should have_many(:scholarships).through(:scholarship_durations) }
  it { should have_many(:accomplishments).dependent(:destroy) }
  it { should have_many(:phases).through(:accomplishments) }
  it { should have_many(:deferrals).dependent(:destroy) }
  it { should have_many(:enrollment_holds).dependent(:destroy) }
  it { should have_many(:class_enrollments).dependent(:destroy) }
  it { should have_many(:thesis_defense_committee_participations).dependent(:destroy) }
  it { should have_many(:thesis_defense_committee_professors).source(:professor).through(:thesis_defense_committee_participations) }
  it { should have_many(:phase_completions).dependent(:destroy) }

  before(:all) do
    @destroy_later = []
    @admission_date = YearSemester.current.semester_begin
    @level = FactoryBot.create(:level)
    @role = FactoryBot.create(:role)
    @student = FactoryBot.create(:student)
    @professor = FactoryBot.create(:professor)
    @dismissal_reason = FactoryBot.create(:dismissal_reason)
    @enrollment_status_with_user = FactoryBot.create(:enrollment_status, user: true)
    @enrollment_status_without_user = FactoryBot.create(:enrollment_status, user: false)
    @course_type = FactoryBot.create(:course_type)
  end

  after(:all) do
    @level.delete
    @role.delete
    @enrollment_status_with_user.delete
    @enrollment_status_without_user.delete
    @student.delete
    @dismissal_reason.delete
    @professor.delete
    @course_type.delete
  end
  let(:enrollment_number) { "M123" }
  let(:student) { FactoryBot.create(:student) }
  let(:enrollment) do
    Enrollment.new(
      enrollment_number: enrollment_number,
      student: student,
      admission_date: @admission_date,
      enrollment_status: @enrollment_status_without_user,
      level: @level
    )
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  subject { enrollment }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:student).required(true) }
    it { should belong_to(:level).required(true) }
    it { should belong_to(:enrollment_status).required(true) }
    it { should belong_to(:research_area).required(false) }
    it { should validate_presence_of(:enrollment_number) }
    it { should validate_uniqueness_of(:enrollment_number) }
    it { should validate_presence_of(:admission_date) }
    it { should accept_a_month_year_assignment_of(:admission_date, presence: true) }

    describe "student" do
      context "should have advisment error when it" do
        it "has just one advisor that is not a main advisor" do
          enrollment.advisements.build(main_advisor: false)
          expect(enrollment).not_to be_valid
          expect(enrollment).to have_error(:main_advisor_required).on(:base)
        end
        it "has more than one main advisor" do
          enrollment.advisements.build(main_advisor: true)
          enrollment.advisements.build(main_advisor: true)
          expect(enrollment).not_to be_valid
          expect(enrollment).to have_error(:main_advisor_uniqueness).on(:base)
        end
      end
    end
    describe "thesis_defense_date" do
      context "should be valid when" do
        it "is after admission_date" do
          enrollment.thesis_defense_date = @admission_date + 3.months
          expect(enrollment).to have(0).errors_on :thesis_defense_date
        end
      end
      context "should not be valid when" do
        it "is before admission_date" do
          enrollment.thesis_defense_date = @admission_date - 3.months
          expect(enrollment).to have_error(:thesis_defense_date_before_admission_date).on :thesis_defense_date
        end
      end
    end
    describe "research_area" do
      before(:each) do
        @research_area = FactoryBot.build(:research_area)
        enrollment.research_area = @research_area
      end
      let(:research_area) {  }
      context "should be valid when" do
        it "is the same research_area as the advisor" do
          professor = FactoryBot.build(:professor, research_areas: [@research_area])
          enrollment.advisements.build(professor: professor)
          expect(enrollment).to have(0).errors_on :research_area
        end

        it "there is no advisor" do
          expect(enrollment).to have(0).errors_on :research_area
        end
      end
      context "should not be valid when" do
        it "is not the same area as the advisor" do
          another_research_area = FactoryBot.build(:research_area)
          professor = FactoryBot.build(:professor, research_areas: [another_research_area])
          enrollment.advisements.build(professor: professor)
          expect(enrollment).to have_error(:research_area_different_from_professors).on(:research_area)
        end
      end
    end
    describe "enrollment_holds" do
      context "should be valid when" do
        it "enrollment_hold ocurrs after admission date and before dismissal date" do
          enrollment.dismissal = FactoryBot.build(:dismissal, date: @admission_date + 4.years)
          enrollment.enrollment_holds.build(
            year: @admission_date.year + 2, semester: 1, number_of_semesters: 1
          )
          expect(enrollment).to have(0).errors_on :enrollment_holds
        end
      end
      context "should have error invalid" do
        it "enrollment_hold ocurrs before admission date" do
          enrollment.enrollment_holds.build(
            year: @admission_date.year - 5, semester: 1, number_of_semesters: 1
          )
          expect(enrollment).to have_error(:invalid).on :enrollment_holds
        end
        it "enrollment_hold ocurrs after dismissal date" do
          enrollment.dismissal = FactoryBot.build(:dismissal, date: @admission_date + 4.years)
          enrollment.enrollment_holds.build(
            year: @admission_date.year + 6, semester: 1, number_of_semesters: 1
          )
          expect(enrollment).to have_error(:invalid).on :enrollment_holds
        end
      end
    end
  end
  describe "Class Methods" do
    describe "self.has_active_scholarship_now?" do
      describe "has no scholarship" do
        it "should return false" do
          expect(enrollment.has_active_scholarship_now?).to be false
        end
      end
      describe "have scholarship(s) but none of them are active today" do
        it "should return false" do
          scholar1 = FactoryBot.build(:scholarship, start_date: Date.today - 2.years, end_date: Date.today + 2.years)
          scholar2 = FactoryBot.build(:scholarship, start_date: Date.today - 2.years, end_date: Date.today + 2.years)
          enrollment.scholarship_durations.build(start_date: Date.today - 12.months, end_date: Date.today - 6.months,
                                                 cancel_date: Date.today - 6.months, scholarship: scholar1)
          enrollment.scholarship_durations.build(start_date: Date.today + 6.months, end_date: Date.today + 12.months,
                                                 cancel_date: Date.today + 12.months, scholarship: scholar2)
          expect(enrollment.has_active_scholarship_now?).to be false
        end
      end
      describe "has an active scholarship today" do
        it "should return true" do
          scholar = FactoryBot.build(:scholarship, start_date: Date.today - 2.years, end_date: Date.today + 2.years)

          enrollment.scholarship_durations.build(start_date: Date.today - 6.months, end_date: Date.today + 6.months,
                                                 cancel_date: Date.today + 6.months, scholarship: scholar)
          expect(enrollment.has_active_scholarship_now?).to be true
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "M213"
        enrollment.enrollment_number = enrollment_number
        student_name = "Student"
        enrollment.student.name = student_name
        expect(enrollment.to_label).to eql("#{enrollment_number} - #{student_name}")
      end
    end
    describe "should_have_user?" do
      it "should return false if the enrollment status do not allow users" do
        expect(enrollment.should_have_user?).to eq(false)
      end
      describe "enrollment_status_with_user" do
        before(:each) do
          student.email = "abc@def.com"
          enrollment.enrollment_status = @enrollment_status_with_user
        end
        it "should return false if the student already has an user" do
          @destroy_later << FactoryBot.create(:user, email: "abc@def.com", role: @role)
          expect(enrollment.should_have_user?).to eq(false)
        end
        it "should return true if the student was not dismissed and new_user_mode is 'default'" do
          enrollment.new_user_mode = "default"
          expect(enrollment.should_have_user?).to eq(true)
        end
        it "should return false if the student was not dismissed and new_user_mode is 'dismissed'" do
          enrollment.new_user_mode = "dismissed"
          expect(enrollment.should_have_user?).to eq(false)
        end
        it "should return true if the student was not dismissed and new_user_mode is 'all'" do
          enrollment.new_user_mode = "all"
          expect(enrollment.should_have_user?).to eq(true)
        end
        it "should return false if the enrollment was dismissed and new_user_mode is 'default'" do
          enrollment.build_dismissal(dismissal_reason: @dismissal_reason)
          enrollment.new_user_mode = "default"
          expect(enrollment.should_have_user?).to eq(false)
        end
        it "should return true if the enrollment was dismissed and new_user_mode is 'dismissed'" do
          @destroy_later << FactoryBot.create(:student, email: "abc@def.com")
          enrollment.build_dismissal(dismissal_reason: @dismissal_reason)
          enrollment.new_user_mode = "dismissed"
          expect(enrollment.should_have_user?).to eq(true)
        end
        it "should return true if the enrollment was dismissed and new_user_mode is 'all'" do
          @destroy_later << FactoryBot.create(:student, email: "abc@def.com")
          enrollment.build_dismissal(dismissal_reason: @dismissal_reason)
          enrollment.new_user_mode = "all"
          expect(enrollment.should_have_user?).to eq(true)
        end
      end
    end
  end
  describe "Scenario 2: delayed and expired phases" do
    before(:all) do
      @delayed_enrollment = FactoryBot.create(:enrollment, admission_date: @admission_date, level: @level, enrollment_status: @enrollment_status_without_user, student: @student)
      @inactive_enrollment = FactoryBot.create(:enrollment, level: @level, admission_date: @admission_date, enrollment_status: @enrollment_status_without_user, student: @student)
      @inactive_dismissal = FactoryBot.create(:dismissal, enrollment: @inactive_enrollment,
                                                          date: (YearSemester.current.semester_begin + 1.month),
                                                          dismissal_reason: @dismissal_reason)

      @one_month_phase = FactoryBot.create(:phase)
      @one_month_phase_duration = FactoryBot.create(
        :phase_duration, deadline_days: 0, deadline_months: 1, deadline_semesters: 0,
                         level: @level, phase: @one_month_phase
      )
      @two_semesters_phase = FactoryBot.create(:phase)
      @two_semesters_phase_duration = FactoryBot.create(
        :phase_duration, deadline_days: 0, deadline_months: 0, deadline_semesters: 2,
                         level: @level, phase: @two_semesters_phase
      )
      @enrollment_accomplished = FactoryBot.create(:enrollment, level: @level, admission_date: @admission_date, enrollment_status: @enrollment_status_without_user, student: @student)
      @one_month_accomplishment = FactoryBot.create(
        :accomplishment, enrollment: @enrollment_accomplished, phase: @one_month_phase, conclusion_date: 1.day.ago
      )

      @enrollment_active_deferral = FactoryBot.create(:enrollment, level: @level, admission_date: @admission_date, enrollment_status: @enrollment_status_without_user, student: @student)
      @one_semester_deferral_type = FactoryBot.create(
        :deferral_type, phase: @one_month_phase, duration_days: 0, duration_months: 0, duration_semesters: 1
      )
      @active_deferral = FactoryBot.create(:deferral, enrollment: @enrollment_active_deferral,
                                                      deferral_type: @one_semester_deferral_type)

      @enrollment_expired_deferral = FactoryBot.create(:enrollment, level: @level,
                                                                    admission_date: (@admission_date - 8.months), enrollment_status: @enrollment_status_without_user, student: @student)
      @expired_deferral = FactoryBot.create(:deferral, enrollment: @enrollment_expired_deferral,
                                                      deferral_type: @one_semester_deferral_type)
    end
    after(:all) do
      PhaseCompletion.delete_all
      @expired_deferral.delete
      @enrollment_expired_deferral.delete
      @active_deferral.delete
      @one_semester_deferral_type.delete
      @enrollment_active_deferral.delete
      @one_month_accomplishment.delete
      @enrollment_accomplished.delete
      @two_semesters_phase_duration.delete
      @two_semesters_phase.delete
      @one_month_phase_duration.delete
      @one_month_phase.delete
      @inactive_dismissal.delete
      @inactive_enrollment.delete
      @delayed_enrollment.delete
    end

    describe "Class Methods" do
      describe "self.with_delayed_phases_on" do
        it "should return the expected enrollments" do
          result = Enrollment.with_delayed_phases_on(YearSemester.current.semester_begin + 2.months, nil)

          expected_result = [@delayed_enrollment.id, @enrollment_expired_deferral.id].sort
          expect(result.sort).to eql(expected_result.sort)
        end
      end
      describe "self.with_all_phases_accomplished_on" do
        it "should return the expected enrollments" do
          @destroy_later << FactoryBot.create(:accomplishment, enrollment: @enrollment_accomplished, phase: @two_semesters_phase,
                                             conclusion_date: 1.day.ago)

          result = Enrollment.with_all_phases_accomplished_on(Date.today)

          expected_result = [@enrollment_accomplished.id].sort
          expect(result.sort).to eql(expected_result.sort)
        end
      end
    end
  end
  describe "Scenario 3: gpr calculation" do
    before(:all) do
      @destroy_all = []
      @destroy_all << with_grade = FactoryBot.create(:course_type, has_score: true)
      @destroy_all << without_grade = FactoryBot.create(:course_type, has_score: nil)
      # create courses by number of credits
      courses = [4, 6, 6, 4, 2, 4].collect do |credits|
        @destroy_all << course = FactoryBot.create(:course, credits: credits, course_type: with_grade)
        course
      end
      courses[4].course_type = without_grade
      courses[4].save

      @destroy_all << @enrollment = FactoryBot.create(:enrollment, admission_date: @admission_date, student: @student, level: @level, enrollment_status: @enrollment_status_without_user)

      # create classes and grades
      [
        ["2012", "1", courses[0], 80, "aproved"],
        ["2012", "1", courses[1], 50, "disapproved"],
        ["2012", "2", courses[2], 90, "aproved"],
        ["2013", "1", courses[1], 100, "aproved"],
        ["2013", "1", courses[4], nil, "aproved"],
        ["2013", "1", courses[3], 97, "aproved"],
        ["2013", "1", courses[5], nil, "registered"],
        ["2013", "2", courses[5], nil, "registered"]
      ].each do |year, semester, course, grade, situation|
        @destroy_all << course_class = FactoryBot.create(:course_class, year: year, semester: semester, course: course, professor: @professor)
        @destroy_all << class_enrollment = FactoryBot.create(:class_enrollment, enrollment: @enrollment, course_class: course_class)
        class_enrollment.situation = I18n.translate(
          "activerecord.attributes.class_enrollment.situations.#{situation}"
        )
        class_enrollment.grade = grade unless grade.nil?
        class_enrollment.save
      end
    end
    after(:all) do
      @destroy_all.each(&:delete)
    end

    describe "Methods" do
      describe "gpr_by_semester" do
        it "should return 90 for 2012.2 (testing 1 grade)" do
          expect(@enrollment.gpr_by_semester(2012, 2)).to eq(90)
        end

        it "should return 62 for 2012.1 (testing 2 grades)" do
          expect(@enrollment.gpr_by_semester(2012, 1)).to eq(62)
        end

        it "should return 0 for 2013.2 (testing 1 incomplete class)" do
          expect(@enrollment.gpr_by_semester(2013, 2)).to be_nil
        end

        it "should return 99 for 2013.1 (testing 2 grades, 1 incomplete class, 1 approved class without grade)" do
          expect(@enrollment.gpr_by_semester(2013, 1).round(0)).to eq(99)
        end

        it "should return 0 if it is not enrolled in any classes of the semester" do
          expect(@enrollment.gpr_by_semester(2011, 2)).to be_nil
        end

        it "should return 7.75 when one class_enrollment grade not count in gpr" do
          @destroy_later << course_type = FactoryBot.create(:course_type, has_score: true)

          @destroy_later << course1 = FactoryBot.create(:course, course_type: course_type)
          @destroy_later << course2 = FactoryBot.create(:course, course_type: course_type)
          @destroy_later << course3 = FactoryBot.create(:course, course_type: course_type)

          @destroy_later << class1 = FactoryBot.create(:course_class, year: "2021", semester: "1", course: course1, professor: @professor)
          @destroy_later << class2 = FactoryBot.create(:course_class, year: "2021", semester: "1", course: course2, professor: @professor)
          @destroy_later << class3 = FactoryBot.create(:course_class, year: "2021", semester: "1", course: course3, professor: @professor)

          enrollment = FactoryBot.create(:enrollment, student: @student, level: @level)

          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class1, grade: 70, grade_not_count_in_gpr: nil,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))
          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class2, grade: 80, grade_not_count_in_gpr: true,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))
          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class3, grade: 85, grade_not_count_in_gpr: false,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))

          expect((enrollment.gpr_by_semester(2021, 1) * 10).round).to eq(775)
        end
      end

      describe "total_gpr" do
        it "should return 83" do
          expect(@enrollment.total_gpr.round).to eq(83)
        end

        it "should return 8.17 when one class_enrollment grade not count in gpr" do
          @destroy_later << course_type = FactoryBot.create(:course_type, has_score: true)

          @destroy_later << course1 = FactoryBot.create(:course, course_type: course_type)
          @destroy_later << course2 = FactoryBot.create(:course, course_type: course_type)
          @destroy_later << course3 = FactoryBot.create(:course, course_type: course_type)
          @destroy_later << course4 = FactoryBot.create(:course, course_type: course_type)

          @destroy_later << class1 = FactoryBot.create(:course_class, year: "2021", semester: "1", course: course1, professor: @professor)
          @destroy_later << class2 = FactoryBot.create(:course_class, year: "2021", semester: "1", course: course2, professor: @professor)
          @destroy_later << class3 = FactoryBot.create(:course_class, year: "2021", semester: "1", course: course3, professor: @professor)
          @destroy_later << class4 = FactoryBot.create(:course_class, year: "2021", semester: "2", course: course4, professor: @professor)

          @destroy_later << enrollment = FactoryBot.create(:enrollment, student: @student, level: @level)

          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class1, grade: 70, grade_not_count_in_gpr: nil,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))
          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class2, grade: 80, grade_not_count_in_gpr: true,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))
          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class3, grade: 85, grade_not_count_in_gpr: false,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))
          @destroy_later << FactoryBot.create(:class_enrollment,
                            enrollment: enrollment, course_class: class4, grade: 90, grade_not_count_in_gpr: nil,
                            situation: I18n.t("activerecord.attributes.class_enrollment.situations.aproved"))

          expect((enrollment.total_gpr * 10).round).to eq(817)
        end
      end
    end
  end
  describe "Scenario 4: course classes" do
    before(:all) do
      @admission_date = YearSemester.current.semester_begin
      @course1 = FactoryBot.create(:course, course_type: @course_type)
      @course2 = FactoryBot.create(:course, course_type: @course_type)
      @courseX1 = FactoryBot.create(:course, course_type: @course_type)
      @courseX2 = FactoryBot.create(:course, course_type: @course_type)
      @courseX3 = FactoryBot.create(:course, course_type: @course_type)
      @courseX4 = FactoryBot.create(:course, course_type: @course_type)
      @class1 = FactoryBot.create(:course_class, year: "2012", semester: "1", course: @courseX1, professor: @professor)
      @class2 = FactoryBot.create(:course_class, year: "2012", semester: "1", course: @courseX2, professor: @professor)
      @class3 = FactoryBot.create(:course_class, year: "2012", semester: "2", course: @courseX3, professor: @professor)
      @class4 = FactoryBot.create(:course_class, year: "2013", semester: "1", course: @courseX4, professor: @professor)
      @class5 = FactoryBot.create(:course_class, year: "2013", semester: "1", course: @course1, professor: @professor)
      @class6 = FactoryBot.create(:course_class, year: "2013", semester: "2", course: @course1, professor: @professor)
      @class7 = FactoryBot.create(:course_class, year: "2013", semester: "2", course: @course2, professor: @professor)
    end
    after(:all) do
      @class7.delete
      @class6.delete
      @class5.delete
      @class4.delete
      @class3.delete
      @class2.delete
      @class1.delete
      @course2.delete
      @course1.delete
      @courseX1.delete
      @courseX2.delete
      @courseX3.delete
      @courseX4.delete
    end
    describe "Methods" do
      describe "available_semesters" do
        it "should not return any value when the enrollment does not have any classes" do
          expect(enrollment.available_semesters.any?).to be_falsey
        end
        it "should return [[2013,2]] when it is enrolled to a class of 2013.2" do
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class6)
          expect(enrollment.available_semesters.any?).to be_truthy
          expect(enrollment.available_semesters).to eq([[2013, 2]])
        end
        it "should return [[2013,2]] when it is enrolled to more than one class of 2013.2" do
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class6)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class7)
          expect(enrollment.available_semesters.any?).to be_truthy
          expect(enrollment.available_semesters).to eq([[2013, 2]])
        end
        it "should return [[2013, 1], [2013,2]] when it is enrolled a class of 2013.1 and a class of 2013.2" do
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class6)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class5)
          expect(enrollment.available_semesters.any?).to be_truthy
          expect(enrollment.available_semesters).to eq([[2013, 1], [2013, 2]])
        end
        it "should be ordered: [[2012, 1], [2012, 2], [2013, 1], [2013,2]]" do
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class3)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class5)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class1)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class7)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class4)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class2)
          @destroy_later << FactoryBot.create(:class_enrollment, enrollment: enrollment, course_class: @class6)
          expect(enrollment.available_semesters.any?).to be_truthy
          expect(enrollment.available_semesters).to eq([[2012, 1], [2012, 2], [2013, 1], [2013, 2]])
        end
      end
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Enrollment do
  it { should be_able_to_be_destroyed }
  it { should destroy_dependent :accomplishment }
  it { should destroy_dependent :advisement }
  it { should destroy_dependent :class_enrollment }
  it { should destroy_dependent :deferral }
  it { should restrict_destroy_when_exists :dismissal }
  it { should destroy_dependent :scholarship_duration }
  it { should destroy_dependent :thesis_defense_committee_participation }


  let(:enrollment) { Enrollment.new }
  let(:enrollment_status_with_user) { FactoryBot.create(:enrollment_status, :user => true) }
  let(:enrollment_status_without_user) { FactoryBot.create(:enrollment_status, :user => false) }
  let(:role) { FactoryBot.create(:role) }
  subject { enrollment }
  describe "Validations" do
    describe "student" do
      context "should be valid when" do
        it "student is not null" do
          enrollment.student = Student.new
          expect(enrollment).to have(0).errors_on :student
        end
      end
      context "should have error blank when" do
        it "student is null" do
          enrollment.student = nil
          expect(enrollment).to have_error(:blank).on :student
        end
      end
      context "should have advisment error when it" do
        it "has just one advisor that is not a main advisor" do
          enrollment.advisements << FactoryBot.create(:advisement, :main_advisor => false)
          expect(enrollment).not_to be_valid
          expect(enrollment.errors[:base]).to include I18n.translate("activerecord.errors.models.enrollment.main_advisor_required")
        end

        it "has more than one main advisor" do
          enrollment.advisements << advisement1 = FactoryBot.create(:advisement, :main_advisor => true)
          enrollment.advisements << advisement2 = FactoryBot.create(:advisement, :main_advisor => true)
          expect(enrollment).not_to be_valid
          expect(enrollment.errors[:base]).to include I18n.translate("activerecord.errors.models.enrollment.main_advisor_uniqueness")
        end
      end
    end
    describe "enrollment_status" do
      context "should be valid when" do
        it "enrollment_status is not null" do
          enrollment.enrollment_status = EnrollmentStatus.new
          expect(enrollment).to have(0).errors_on :enrollment_status
        end
      end
      context "should have error blank when" do
        it "enrollment_status is null" do
          enrollment.enrollment_status = nil
          expect(enrollment).to have_error(:blank).on :enrollment_status
        end
      end
    end
    describe "level" do
      context "should be valid when" do
        it "level is not null" do
          enrollment.level = Level.new
          expect(enrollment).to have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          enrollment.level = nil
          expect(enrollment).to have_error(:blank).on :level
        end
      end
    end
    describe "enrollment_number" do
      context "should be valid when" do
        it "enrollment_number is not null and is not taken" do
          enrollment.enrollment_number = "M123"
          expect(enrollment).to have(0).errors_on :enrollment_number
        end
      end
      context "should have error blank when" do
        it "enrollment_number is null" do
          enrollment.enrollment_number = nil
          expect(enrollment).to have_error(:blank).on :enrollment_number
        end
      end
      context "should have error taken when" do
        it "enrollment_number is already in use" do
          enrollment_number = "D123"
          FactoryBot.create(:enrollment, :enrollment_number => enrollment_number)
          enrollment.enrollment_number = enrollment_number
          expect(enrollment).to have_error(:taken).on :enrollment_number
        end
      end
    end
    describe "thesis_defense_date" do
      context "should be valid when" do
        it "is after admission_date" do
          enrollment = FactoryBot.create(:enrollment, :admission_date => 3.days.ago.to_date)
          enrollment.thesis_defense_date = 3.days.from_now.to_date
          expect(enrollment).to have(0).errors_on :thesis_defense_date
        end
      end
      context "should not be valid when" do
        it "is before admission_date" do
          enrollment = FactoryBot.create(:enrollment, :admission_date => 3.days.ago.to_date)
          enrollment.thesis_defense_date = 4.days.ago.to_date
          expect(enrollment).to have_error(:thesis_defense_date_before_admission_date).on :thesis_defense_date
        end
      end
    end

    describe "research_area" do
      context "should be valid when" do
        it "is empty" do
          enrollment = FactoryBot.create(:enrollment, :research_area => nil)
          expect(enrollment).to have(0).errors_on :research_area
        end

        it "is the same research_area as the advisor" do
          research_area = FactoryBot.create(:research_area) 
          enrollment = FactoryBot.create(:enrollment, :research_area => research_area)
          professor = FactoryBot.create(:professor, :research_areas => [research_area])
          FactoryBot.create(:advisement, :enrollment => enrollment, :professor => professor)
          expect(enrollment).to have(0).errors_on :research_area
        end

        it "there is no advisor" do
          research_area = FactoryBot.create(:research_area) 
          enrollment = FactoryBot.create(:enrollment, :research_area => research_area)
          expect(enrollment).to have(0).errors_on :research_area
        end
      end
      context "should not be valid when" do
        it "is not the same area as the advisor" do
          research_area1 = FactoryBot.create(:research_area) 
          research_area2 = FactoryBot.create(:research_area) 
          enrollment = FactoryBot.create(:enrollment, :research_area => research_area1)
          professor = FactoryBot.create(:professor, :research_areas => [research_area2])
          FactoryBot.create(:advisement, :enrollment => enrollment, :professor => professor)
          enrollment.save
          expect(enrollment.errors[:research_area]).to include I18n.translate("activerecord.errors.models.enrollment.research_area_different_from_professors")
        end
      end
    end
  end
  describe "Methods" do
    before(:all) do
      admission_date = YearSemester.current.semester_begin
      @delayed_enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)
      level = @delayed_enrollment.level


      inactive_enrollment = FactoryBot.create(:enrollment, :level => level, :admission_date => admission_date)
      FactoryBot.create(:dismissal, :enrollment => inactive_enrollment, :date => (YearSemester.current.semester_begin + 1.month))

      one_month_phase = FactoryBot.create(:phase)
      FactoryBot.create(:phase_duration, :deadline_days => 0, :deadline_months => 1, :deadline_semesters => 0, :level => level, :phase => one_month_phase)
      @two_semesters_phase = FactoryBot.create(:phase)
      FactoryBot.create(:phase_duration, :deadline_days => 0, :deadline_months => 0, :deadline_semesters => 2, :level => level, :phase => @two_semesters_phase)

      @enrollment_accomplished = FactoryBot.create(:enrollment, :level => @delayed_enrollment.level, :admission_date => admission_date)
      FactoryBot.create(:accomplishment, :enrollment => @enrollment_accomplished, :phase => one_month_phase, :conclusion_date => 1.day.ago)

      enrollment_active_deferral = FactoryBot.create(:enrollment, :level => level, :admission_date => admission_date)
      one_semester_deferral_type = FactoryBot.create(:deferral_type, :phase => one_month_phase, :duration_days => 0, :duration_months => 0, :duration_semesters => 1)
      FactoryBot.create(:deferral, :enrollment => enrollment_active_deferral, :deferral_type => one_semester_deferral_type)

      @enrollment_expired_deferral = FactoryBot.create(:enrollment, :level => level, :admission_date => (admission_date - 8.months))
      FactoryBot.create(:deferral, :enrollment => @enrollment_expired_deferral, :deferral_type => one_semester_deferral_type)

    end

    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "M213"
        enrollment.enrollment_number = enrollment_number
        student_name = "Student"
        enrollment.student = Student.new(:name => student_name)
        expect(enrollment.to_label).to eql("#{enrollment_number} - #{student_name}")
      end
    end
    describe "self.with_delayed_phases_on" do
      it "should return the expected enrollments" do
        result = Enrollment.with_delayed_phases_on(YearSemester.current.semester_begin + 2.months, nil)

        expected_result = [@delayed_enrollment.id, @enrollment_expired_deferral.id].sort
        expect(result.sort).to eql(expected_result.sort)
      end
    end
    describe "self.with_all_phases_accomplished_on" do
      it "should return the expected enrollments" do
        FactoryBot.create(:accomplishment, :enrollment => @enrollment_accomplished, :phase => @two_semesters_phase, :conclusion_date => 1.day.ago)
        
        result = Enrollment.with_all_phases_accomplished_on(Date.today)

        expected_result = [@enrollment_accomplished.id].sort
        expect(result.sort).to eql(expected_result.sort)
      end
    end

    describe "available_semesters" do
      before(:all) do
        course1 = FactoryBot.create(:course);
        course2 = FactoryBot.create(:course);
        @class1 = FactoryBot.create(:course_class, :year => "2012", :semester => "1")
        @class2 = FactoryBot.create(:course_class, :year => "2012", :semester => "1")
        @class3 = FactoryBot.create(:course_class, :year => "2012", :semester => "2")
        @class4 = FactoryBot.create(:course_class, :year => "2013", :semester => "1")
        @class5 = FactoryBot.create(:course_class, :year => "2013", :semester => "1", :course => course1)
        @class6 = FactoryBot.create(:course_class, :year => "2013", :semester => "2", :course => course1)
        @class7 = FactoryBot.create(:course_class, :year => "2013", :semester => "2", :course => course2)
      end
      it "shouldn't return any value when the enrollment doesn't have any classes" do
        admission_date = YearSemester.current.semester_begin
        enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)
        expect(enrollment.available_semesters.any?).to be_falsey
      end

      it "should return [[2013,2]] when it is enrolled to a class of 2013.2" do
        admission_date = YearSemester.current.semester_begin
        enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class6)
        expect(enrollment.available_semesters.any?).to be_truthy
        expect(enrollment.available_semesters).to eq([[2013, 2]])
      end

      it "should return [[2013,2]] when it is enrolled to more than one class of 2013.2" do
        admission_date = YearSemester.current.semester_begin
        enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class6)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class7)
        expect(enrollment.available_semesters.any?).to be_truthy
        expect(enrollment.available_semesters).to eq([[2013, 2]])
      end

      it "should return [[2013, 1], [2013,2]] when it is enrolled a class of 2013.1 and a class of 2013.2" do
        admission_date = YearSemester.current.semester_begin
        enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class6)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class5)
        expect(enrollment.available_semesters.any?).to be_truthy
        expect(enrollment.available_semesters).to eq([[2013, 1], [2013, 2]])
      end

      it "should be ordered: [[2012, 1], [2012, 2], [2013, 1], [2013,2]]" do
        admission_date = YearSemester.current.semester_begin
        enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class3)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class5)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class1)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class7)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class4)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class2)
        FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => @class6)
        expect(enrollment.available_semesters.any?).to be_truthy
        expect(enrollment.available_semesters).to eq([[2012, 1], [2012, 2], [2013, 1], [2013,2]])
      end
    end

    describe "gpr" do

      before(:each) do
        with_grade = FactoryBot.create(:course_type, :has_score => true)
        without_grade = FactoryBot.create(:course_type, :has_score => nil)
        # create courses by number of credits
        courses = [4, 6, 6, 4, 2, 4].collect { |credits| FactoryBot.create(:course, :credits => credits, :course_type => with_grade) }
        courses[4].course_type = without_grade
        courses[4].save

        admission_date = YearSemester.current.semester_begin
        @enrollment = FactoryBot.create(:enrollment, :admission_date => admission_date)

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
          course_class = FactoryBot.create(:course_class, :year => year, :semester => semester, :course => course)
          class_enrollment = FactoryBot.create(:class_enrollment, :enrollment => @enrollment, :course_class => course_class)
          class_enrollment.situation = I18n.translate("activerecord.attributes.class_enrollment.situations." + situation)
          class_enrollment.grade = grade unless grade.nil?
          class_enrollment.save
        end
      end

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
          course_type = FactoryBot.create(:course_type, :has_score => true)  

          course1 = FactoryBot.create(:course, :course_type => course_type)
          course2 = FactoryBot.create(:course, :course_type => course_type)
          course3 = FactoryBot.create(:course, :course_type => course_type)   
          
          class1 = FactoryBot.create(:course_class, :year => "2021", :semester => "1", :course => course1)
          class2 = FactoryBot.create(:course_class, :year => "2021", :semester => "1", :course => course2)
          class3 = FactoryBot.create(:course_class, :year => "2021", :semester => "1", :course => course3)
        
          enrollment = FactoryBot.create(:enrollment)
 
          class_enrollment1 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class1, :grade => 70 , :grade_not_count_in_gpr => nil, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )
          class_enrollment2 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class2, :grade => 80, :grade_not_count_in_gpr => true, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )
          class_enrollment3 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class3, :grade => 85, :grade_not_count_in_gpr => false, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )
 
          expect( (enrollment.gpr_by_semester(2021, 1) * 10).round ).to eq(775)

        end
      end

      describe "total_gpr" do
        it "should return 83" do
          expect(@enrollment.total_gpr.round).to eq(83)
        end

        it "should return 8.17 when one class_enrollment grade not count in gpr" do

          course_type = FactoryBot.create(:course_type, :has_score => true)  

          course1 = FactoryBot.create(:course, :course_type => course_type)
          course2 = FactoryBot.create(:course, :course_type => course_type)
          course3 = FactoryBot.create(:course, :course_type => course_type)   
          course4 = FactoryBot.create(:course, :course_type => course_type)   

          class1 = FactoryBot.create(:course_class, :year => "2021", :semester => "1", :course => course1)
          class2 = FactoryBot.create(:course_class, :year => "2021", :semester => "1", :course => course2)
          class3 = FactoryBot.create(:course_class, :year => "2021", :semester => "1", :course => course3)
          class4 = FactoryBot.create(:course_class, :year => "2021", :semester => "2", :course => course4)

          enrollment = FactoryBot.create(:enrollment)
 
          class_enrollment1 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class1, :grade => 70 , :grade_not_count_in_gpr => nil, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )
          class_enrollment2 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class2, :grade => 80, :grade_not_count_in_gpr => true, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )
          class_enrollment3 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class3, :grade => 85, :grade_not_count_in_gpr => false, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )
          class_enrollment4 = FactoryBot.create(:class_enrollment, :enrollment => enrollment, :course_class => class4, :grade => 90, :grade_not_count_in_gpr => nil, :situation => I18n.t("activerecord.attributes.class_enrollment.situations.aproved") )

          expect( (enrollment.total_gpr * 10).round ).to eq(817)

        end
      end

      
    end

    describe "self.has_active_scholarship_now?" do
      describe "has no scholarship" do
        it "should return false" do
          enrollment = FactoryBot.create(:enrollment)
          expect(enrollment.has_active_scholarship_now?).to be false
        end 
      end

      describe "have scholarship(s) but none of them are active today" do
        it "should return false" do

          enrollment = FactoryBot.create(:enrollment)
          scholarship1 = FactoryBot.create(:scholarship, :start_date => Date.today - 2.years, :end_date => Date.today + 2.years)
          scholarship2 = FactoryBot.create(:scholarship, :start_date => Date.today - 2.years, :end_date => Date.today + 2.years)

          scholarship_duration1 = FactoryBot.create(:scholarship_duration, :start_date => Date.today - 12.months, :end_date => Date.today - 6.months, :cancel_date => Date.today - 6.months, :enrollment => enrollment, :scholarship => scholarship1)

          scholarship_duration2 = FactoryBot.create(:scholarship_duration, :start_date => Date.today + 6.months, :end_date => Date.today + 12.months, :cancel_date => Date.today + 12.months, :enrollment => enrollment, :scholarship => scholarship2)

          enrollment.scholarship_durations << scholarship_duration1
          enrollment.scholarship_durations << scholarship_duration2

          expect(enrollment.has_active_scholarship_now?).to be false
        end
      end

      describe "has an active scholarship today" do
        it "should return true" do

          enrollment = FactoryBot.create(:enrollment)
          scholarship1 = FactoryBot.create(:scholarship, :start_date => Date.today - 2.years, :end_date => Date.today + 2.years)

          scholarship_duration1 = FactoryBot.create(:scholarship_duration, :start_date => Date.today - 6.months, :end_date => Date.today + 6.months, :cancel_date => Date.today + 6.months, :enrollment => enrollment, :scholarship => scholarship1)

          enrollment.scholarship_durations << scholarship_duration1

          expect(enrollment.has_active_scholarship_now?).to be true
        end
      end

    end

    describe "should_have_user?" do
      it "should return false if the enrollment status do not allow users" do
        enrollment = FactoryBot.create(:enrollment, :enrollment_status => enrollment_status_without_user)
        expect(enrollment.should_have_user?).to eq(false)
      end
      it "should return false if the student already has an user" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        FactoryBot.create(:user, :email => 'abc@def.com', :role => role)
        enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        expect(enrollment.should_have_user?).to eq(false)
      end

      it "should return true if the student was not dismissed and new_user_mode is 'default'" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        enrollment.new_user_mode = 'default'
        expect(enrollment.should_have_user?).to eq(true)
      end
      it "should return false if the student was not dismissed and new_user_mode is 'dismissed'" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        enrollment.new_user_mode = 'dismissed'
        expect(enrollment.should_have_user?).to eq(false)
      end
      it "should return true if the student was not dismissed and new_user_mode is 'all'" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        enrollment.new_user_mode = 'all'
        expect(enrollment.should_have_user?).to eq(true)
      end
      
      it "should return false if the enrollment was dismissed and new_user_mode is 'default'" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        dismissed_enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        dismissal_reason = FactoryBot.create(:dismissal_reason, :name => 'a')
        FactoryBot.create(:dismissal, :enrollment => dismissed_enrollment, :dismissal_reason => dismissal_reason)
        dismissed_enrollment.new_user_mode = 'default'
        expect(dismissed_enrollment.should_have_user?).to eq(false)
      end
      it "should return true if the enrollment was dismissed and new_user_mode is 'dismissed'" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        dismissed_enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        dismissal_reason = FactoryBot.create(:dismissal_reason, :name => 'a')
        FactoryBot.create(:dismissal, :enrollment => dismissed_enrollment, :dismissal_reason => dismissal_reason)
        dismissed_enrollment.new_user_mode = 'dismissed'
        expect(dismissed_enrollment.should_have_user?).to eq(true)
      end
      it "should return true if the enrollment was dismissed and new_user_mode is 'all'" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        dismissed_enrollment = FactoryBot.build(:enrollment, :student => student, :enrollment_status => enrollment_status_with_user)
        dismissal_reason = FactoryBot.create(:dismissal_reason, :name => 'a')
        FactoryBot.create(:dismissal, :enrollment => dismissed_enrollment, :dismissal_reason => dismissal_reason)
        dismissed_enrollment.new_user_mode = 'all'
        expect(dismissed_enrollment.should_have_user?).to eq(true)
      end
    end
  end

   
end

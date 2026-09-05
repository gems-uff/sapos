# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

# Safety net for the authorization rules in Ability and Admissions::Ability.
#
# Ability reads only actual_role and the professor/student associations, so most
# users here are built in memory: it keeps the spec fast and avoids fighting the
# role-escalation validation in User#roles_valid?. Users are persisted only where
# a rule matches on user.id.
#
# Rules are order-sensitive: a `cannot` declared after a `can` wins. Several
# examples below exist precisely to pin down that ordering, including the
# prohibitions that apply even to administrators.
RSpec.describe Ability, type: :model do
  def user_for(role_id, professor: nil, student: nil)
    user = User.new(actual_role: role_id)
    user.professor = professor
    user.student = student
    user
  end

  def ability_for(role_id, **kwargs)
    Ability.new(user_for(role_id, **kwargs))
  end

  describe "visitor (not logged in)" do
    subject(:ability) { Ability.new(nil) }

    it "reaches the landing page and nothing else" do
      expect(ability).to be_able_to(:read, :landing)
      expect(ability).not_to be_able_to(:read, :pendency)
      expect(ability).not_to be_able_to(:show, :student_enrollment)
    end

    it "cannot read any domain model" do
      [Student, Enrollment, Professor, Course, User, Query, Notification].each do |model|
        expect(ability).not_to be_able_to(:read, model), "visitor should not read #{model}"
      end
    end

    it "cannot manage anything" do
      expect(ability).not_to be_able_to(:manage, :all)
      expect(ability).not_to be_able_to(:create, Student)
      expect(ability).not_to be_able_to(:destroy, Student)
    end

    # Admissions::Ability grants these two outside of any role check.
    # ActiveScaffoldWorkaround is a deliberately empty table (see the model).
    # The unconditional :download on FilledFormField is current behavior, not an
    # endorsement -- the file download surface is tracked in its own issue.
    it "keeps the unconditional admissions grants" do
      expect(ability).to be_able_to(:manage, ActiveScaffoldWorkaround)
      expect(ability).to be_able_to(:download, Admissions::FilledFormField)
    end
  end

  describe "unknown role" do
    subject(:ability) { ability_for(Role::ROLE_DESCONHECIDO) }

    it "is no better off than a visitor" do
      expect(ability).to be_able_to(:read, :landing)
      expect(ability).not_to be_able_to(:read, Student)
      expect(ability).not_to be_able_to(:read, :pendency)
      expect(ability).not_to be_able_to(:show, :student_enrollment)
    end
  end

  describe "administrator" do
    subject(:ability) { ability_for(Role::ROLE_ADMINISTRADOR) }

    it "manages everything" do
      expect(ability).to be_able_to(:manage, :all)
      expect(ability).to be_able_to(:read, :pendency)
      expect(ability).to be_able_to(:destroy, Student)
      expect(ability).to be_able_to(:manage, CustomVariable)
      expect(ability).to be_able_to(:manage, Admissions::AdmissionProcess)
    end

    # These prohibitions are declared after `can :manage, :all` and therefore
    # override it. Records of these kinds are created by the application itself,
    # never through the scaffold.
    it "is still blocked from the rules declared after :manage, :all" do
      expect(ability).not_to be_able_to(:create, EnrollmentRequest)
      expect(ability).not_to be_able_to(:destroy, EnrollmentRequest)
      expect(ability).not_to be_able_to(:create, ClassEnrollmentRequest)
      expect(ability).not_to be_able_to(:destroy, ClassEnrollmentRequest)
      expect(ability).not_to be_able_to(:update, NotificationLog)
      expect(ability).not_to be_able_to(:destroy, Role)
      expect(ability).not_to be_able_to(:update, Version)
      expect(ability).not_to be_able_to(:create, Admissions::AdmissionApplication)
      expect(ability).not_to be_able_to(:update, Admissions::FilledForm)
    end

    # initialize_courses removes this from every manager that is neither
    # coordination nor secretary.
    it "does not read course pendencies" do
      expect(ability).not_to be_able_to(:read_pendencies, ClassEnrollmentRequest)
      expect(ability).not_to be_able_to(:read_pendencies, CourseClass)
    end
  end

  describe "coordination" do
    subject(:ability) { ability_for(Role::ROLE_COORDENACAO) }

    it "manages the academic domain" do
      expect(ability).to be_able_to(:manage, Student)
      expect(ability).to be_able_to(:manage, Professor)
      expect(ability).to be_able_to(:manage, Scholarship)
      expect(ability).to be_able_to(:manage, Course)
      expect(ability).to be_able_to(:manage, Query)
      expect(ability).to be_able_to(:read, :pendency)
      expect(ability).to be_able_to(:read_pendencies, ClassEnrollmentRequest)
    end

    it "manages users but not custom variables" do
      expect(ability).to be_able_to(:manage, User)
      expect(ability).to be_able_to(:manage, EmailTemplate)
      expect(ability).not_to be_able_to(:update, CustomVariable)
      expect(ability).not_to be_able_to(:read, CustomVariable)
    end

    it "cannot touch report configurations" do
      expect(ability).not_to be_able_to(:manage, ReportConfiguration)
      expect(ability).not_to be_able_to(:update, ReportConfiguration)
    end

    it "manages the whole admissions configuration" do
      expect(ability).to be_able_to(:manage, Admissions::AdmissionProcess)
      expect(ability).to be_able_to(:manage, Admissions::FormTemplate)
      expect(ability).to be_able_to(:manage, Admissions::RankingConfig)
    end
  end

  describe "secretary" do
    subject(:ability) { ability_for(Role::ROLE_SECRETARIA) }

    it "manages the academic domain like the other managers" do
      expect(ability).to be_able_to(:manage, Student)
      expect(ability).to be_able_to(:manage, Enrollment)
      expect(ability).to be_able_to(:manage, Course)
      expect(ability).to be_able_to(:read, :pendency)
      expect(ability).to be_able_to(:read_pendencies, ClassEnrollmentRequest)
    end

    it "reads documents but does not change them" do
      expect(ability).to be_able_to(:read, Query)
      expect(ability).to be_able_to(:read, Notification)
      expect(ability).to be_able_to(:read, Assertion)
      expect(ability).not_to be_able_to(:update, Query)
      expect(ability).not_to be_able_to(:create, Notification)
      expect(ability).not_to be_able_to(:destroy, Assertion)
      expect(ability).not_to be_able_to(:read, ReportConfiguration)
    end

    it "invites users without managing them" do
      expect(ability).to be_able_to(:invite, User)
      expect(ability).not_to be_able_to(:update, User)
      expect(ability).not_to be_able_to(:destroy, User)
      expect(ability).not_to be_able_to(:read, CustomVariable)
    end

    it "gets a reduced set of admissions permissions" do
      expect(ability).to be_able_to(:manage, Admissions::AdmissionProcess)
      expect(ability).to be_able_to(:read, Admissions::FormTemplate)
      expect(ability).not_to be_able_to(:update, Admissions::FormTemplate)
      expect(ability).to be_able_to(:update, Admissions::AdmissionApplication)
      expect(ability).not_to be_able_to(:destroy, Admissions::AdmissionApplication)
    end
  end

  describe "support" do
    subject(:ability) { ability_for(Role::ROLE_SUPORTE) }

    it "only reaches students, to fix their data and photo" do
      expect(ability).to be_able_to(:read, Student)
      expect(ability).to be_able_to(:update, Student)
      expect(ability).to be_able_to(:update_only_photo, Student)
      expect(ability).to be_able_to(:read, :pendency)
    end

    it "cannot destroy students nor reach the rest of the system" do
      expect(ability).not_to be_able_to(:destroy, Student)
      expect(ability).not_to be_able_to(:read, Professor)
      expect(ability).not_to be_able_to(:read, Scholarship)
      expect(ability).not_to be_able_to(:read, User)
      expect(ability).not_to be_able_to(:read, Query)
    end
  end

  describe "professor" do
    before(:all) do
      @professor = FactoryBot.create(:professor)
      @other_professor = FactoryBot.create(:professor)
    end

    after(:all) do
      Grant.destroy_all
      Paper.destroy_all
      Professor.destroy_all
    end

    subject(:ability) { ability_for(Role::ROLE_PROFESSOR, professor: @professor) }

    it "reads the academic domain without changing it" do
      expect(ability).to be_able_to(:read, Student)
      expect(ability).to be_able_to(:read, Professor)
      expect(ability).to be_able_to(:read, Scholarship)
      expect(ability).to be_able_to(:read, Course)
      expect(ability).to be_able_to(:read, :pendency)

      expect(ability).not_to be_able_to(:update, Student)
      expect(ability).not_to be_able_to(:destroy, Professor)
      expect(ability).not_to be_able_to(:read, User)
      expect(ability).not_to be_able_to(:read, Query)
      expect(ability).not_to be_able_to(:read, CustomVariable)
    end

    it "changes only its own grants" do
      own = FactoryBot.create(:grant, professor: @professor)
      other = FactoryBot.create(:grant, professor: @other_professor)

      expect(ability).to be_able_to(:create, Grant)
      expect(ability).to be_able_to(:update, own)
      expect(ability).to be_able_to(:destroy, own)
      expect(ability).not_to be_able_to(:update, other)
      expect(ability).not_to be_able_to(:destroy, other)
      expect(ability).not_to be_able_to(:edit_professor, Grant)
    end

    it "changes only the papers it owns" do
      own = FactoryBot.create(:paper, owner: @professor)
      other = FactoryBot.create(:paper, owner: @other_professor)

      expect(ability).to be_able_to(:create, Paper)
      expect(ability).to be_able_to(:update, own)
      expect(ability).to be_able_to(:destroy, own)
      expect(ability).not_to be_able_to(:update, other)
      expect(ability).not_to be_able_to(:destroy, other)
      expect(ability).not_to be_able_to(:edit_professor, Paper)
    end

    # initialize_professors builds its conditions straight from user.professor,
    # with no `present?` guard (initialize_courses has one). A missing association
    # degrades the condition to `professor: nil`, which grants rather than denies.
    # It is inert today only because Grant#professor and Paper#owner are
    # `optional: false`, so no record can match -- the guard is missing, the
    # exposure is not. These examples pin the safe outcome so that a future model
    # change making the association optional fails here instead of in production.
    context "when the user has the role but no professor record" do
      subject(:ability) { ability_for(Role::ROLE_PROFESSOR) }

      it "still reads the domain but owns nothing" do
        own = FactoryBot.create(:grant, professor: @professor)
        paper = FactoryBot.create(:paper, owner: @professor)

        expect(ability).to be_able_to(:read, Professor)
        expect(ability).not_to be_able_to(:update, own)
        expect(ability).not_to be_able_to(:destroy, own)
        expect(ability).not_to be_able_to(:update, paper)
        expect(ability).not_to be_able_to(:destroy, paper)
      end

      it "cannot reach records with no owner, because none can exist" do
        expect(Grant.new(professor: nil)).not_to be_valid
        expect(Paper.new(owner: nil)).not_to be_valid
      end
    end

    context "grade import policy" do
      before(:all) do
        @import_professor = FactoryBot.create(:professor)
        @other_import_professor = FactoryBot.create(:professor)
        @own_class_current_semester = FactoryBot.create(
          :course_class, professor: @import_professor,
          year: YearSemester.current.year, semester: YearSemester.current.semester
        )
        @own_class_past_semester = FactoryBot.create(
          :course_class, professor: @import_professor,
          year: YearSemester.current.year - 1, semester: YearSemester.current.semester
        )
        @other_class = FactoryBot.create(
          :course_class, professor: @other_import_professor,
          year: YearSemester.current.year, semester: YearSemester.current.semester
        )
      end

      after(:all) do
        CourseClass.destroy_all
        Professor.where(id: [@import_professor.id, @other_import_professor.id]).destroy_all
      end

      before(:each) do
        @original_policy = CustomVariable.find_by(variable: "professor_login_can_post_grades")&.value
      end

      after(:each) do
        variable = CustomVariable.find_or_initialize_by(variable: "professor_login_can_post_grades")
        variable.value = @original_policy
        variable.save(validate: false)
      end

      def set_policy(value)
        variable = CustomVariable.find_or_initialize_by(variable: "professor_login_can_post_grades")
        variable.value = value
        variable.save(validate: false)
      end

      subject(:ability) { ability_for(Role::ROLE_PROFESSOR, professor: @import_professor) }

      it "is denied entirely when the policy is off" do
        set_policy("no")

        expect(ability).not_to be_able_to(:import_grades_xls, @own_class_current_semester)
        expect(ability).not_to be_able_to(:import_grades_xls, @other_class)
      end

      it "is allowed only for the professor's own class in the current semester, when the policy is 'yes'" do
        set_policy("yes")

        expect(ability).to be_able_to(:import_grades_xls, @own_class_current_semester)
        expect(ability).not_to be_able_to(:import_grades_xls, @own_class_past_semester)
        expect(ability).not_to be_able_to(:import_grades_xls, @other_class)
      end

      it "is allowed for the professor's own class in any semester, when the policy is 'yes_all_semesters'" do
        set_policy("yes_all_semesters")

        expect(ability).to be_able_to(:import_grades_xls, @own_class_current_semester)
        expect(ability).to be_able_to(:import_grades_xls, @own_class_past_semester)
        expect(ability).not_to be_able_to(:import_grades_xls, @other_class)
      end
    end
  end

  describe "student" do
    before(:all) do
      @approved_reason = FactoryBot.create(
        :dismissal_reason, thesis_judgement: DismissalReason::APPROVED
      )
      @student = FactoryBot.create(:student)
      @other_student = FactoryBot.create(:student)
      @enrollment = FactoryBot.create(:enrollment, student: @student)
      @other_enrollment = FactoryBot.create(:enrollment, student: @other_student)
    end

    after(:all) do
      Dismissal.destroy_all
      Enrollment.destroy_all
      Student.destroy_all
      DismissalReason.destroy_all
      EnrollmentStatus.destroy_all
      Level.destroy_all
    end

    subject(:ability) { ability_for(Role::ROLE_ALUNO, student: @student) }

    it "reaches its own enrollment pages and nothing administrative" do
      expect(ability).to be_able_to(:show, :student_enrollment)
      expect(ability).to be_able_to(:enroll, :student_enrollment)

      expect(ability).not_to be_able_to(:read, Student)
      expect(ability).not_to be_able_to(:read, Professor)
      expect(ability).not_to be_able_to(:read, :pendency)
      expect(ability).not_to be_able_to(:read, User)
    end

    it "downloads the grades report only for its own enrollment" do
      expect(ability).to be_able_to(:grades_report_pdf, @enrollment)
      expect(ability).not_to be_able_to(:grades_report_pdf, @other_enrollment)
    end

    it "downloads the transcript only when its own enrollment was approved" do
      expect(ability).not_to be_able_to(:academic_transcript_pdf, @enrollment)

      FactoryBot.create(
        :dismissal, enrollment: @enrollment, dismissal_reason: @approved_reason
      )
      @enrollment.reload

      expect(ability).to be_able_to(:academic_transcript_pdf, @enrollment)
      expect(ability).not_to be_able_to(:academic_transcript_pdf, @other_enrollment)
    end

    context "when the role is set but no student record is linked" do
      subject(:ability) { ability_for(Role::ROLE_ALUNO) }

      it "is denied the student pages" do
        expect(ability).not_to be_able_to(:show, :student_enrollment)
        expect(ability).not_to be_able_to(:enroll, :student_enrollment)
      end
    end
  end

  describe "action aliases" do
    subject(:ability) { ability_for(Role::ROLE_PROFESSOR, professor: FactoryBot.create(:professor)) }

    after(:all) { Professor.destroy_all }

    it "treats the read-only scaffold actions as :read" do
      expect(ability).to be_able_to(:list, Student)
      expect(ability).to be_able_to(:show_search, Student)
      expect(ability).to be_able_to(:to_pdf, Student)
      expect(ability).to be_able_to(:browse, Student)
    end

    it "treats the scaffold write actions as :update, which a professor lacks" do
      expect(ability).not_to be_able_to(:update_column, Student)
      expect(ability).not_to be_able_to(:duplicate, Student)
      expect(ability).not_to be_able_to(:delete, Student)
    end
  end
end

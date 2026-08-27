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

    # The advisement pendencies belong to the professor branch of
    # initialize_courses; its else clause takes them back from everyone else,
    # even from a manager who otherwise manages the whole course domain.
    it "does not read advisement pendencies" do
      expect(ability).not_to be_able_to(:read_advisement_pendencies, EnrollmentRequest)
      expect(ability).not_to be_able_to(:read_pendencies, EnrollmentRequest)
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

    it "changes only the authorship rows of the papers it owns" do
      own = FactoryBot.create(:paper, owner: @professor)
      other = FactoryBot.create(:paper, owner: @other_professor)
      own_professor_row = FactoryBot.create(:paper_professor, paper: own)
      own_student_row = FactoryBot.create(:paper_student, paper: own)
      other_professor_row = FactoryBot.create(:paper_professor, paper: other)
      other_student_row = FactoryBot.create(:paper_student, paper: other)

      expect(ability).to be_able_to(:create, PaperProfessor)
      expect(ability).to be_able_to(:create, PaperStudent)
      expect(ability).to be_able_to(:update, own_professor_row)
      expect(ability).to be_able_to(:destroy, own_professor_row)
      expect(ability).to be_able_to(:update, own_student_row)
      expect(ability).to be_able_to(:destroy, own_student_row)

      expect(ability).not_to be_able_to(:update, other_professor_row)
      expect(ability).not_to be_able_to(:destroy, other_professor_row)
      expect(ability).not_to be_able_to(:update, other_student_row)
      expect(ability).not_to be_able_to(:destroy, other_student_row)
    end

    # An ownerless paper never reaches the database -- Paper#owner is
    # `optional: false`. What does exist is the in-memory paper of the subform:
    # adding an authorship row to a paper that is still unsaved makes
    # ActiveScaffold::Actions::Subform#do_edit_associated build the parent through
    # `new_model`, which skips PapersController#do_new -- the very hook that would
    # assign the owner. It is that row the gem asks `can? :destroy` about, to
    # choose between the "remove" link and an access-denied notice.
    it "removes the authorship rows of an unsaved paper, as the subform builds them" do
      unsaved = Paper.new
      professor_row = unsaved.paper_professors.build
      student_row = unsaved.paper_students.build

      expect(unsaved.owner).to be_nil
      expect(ability).to be_able_to(:destroy, professor_row)
      expect(ability).to be_able_to(:destroy, student_row)
    end

    it "generates assertions for any student, as long as the assertion allows it" do
      expect(ability).to be_able_to(:assertion_pdf, Assertion)
      expect(ability).to be_able_to(
        :generate_assertion, Assertion.new(student_can_generate: true), "M1"
      )
      expect(ability).not_to be_able_to(
        :generate_assertion, Assertion.new(student_can_generate: false), "M1"
      )
    end

    # The grades report is reachable through the :read alias, so the rule that
    # actually decides is the `cannot` block in initialize_students.
    it "does not generate the grades report when the enrollment status forbids it" do
      allowed = FactoryBot.create(:enrollment)
      blocked = FactoryBot.create(:enrollment, enrollment_status: FactoryBot.create(
        :enrollment_status, professor_can_generate_report: false
      ))

      expect(ability).to be_able_to(:grades_report_pdf, allowed)
      expect(ability).not_to be_able_to(:grades_report_pdf, blocked)
    end

    # Advisement demands the professor be authorized at the enrollment level, so
    # the authorization comes along even though no rule here looks at it.
    #
    # Both reloads are load-bearing, and neither is obvious:
    #
    # - the professor is shared by the whole group, so an earlier example may
    #   have left its advisement_authorizations loaded. Advisement validates
    #   through that very collection, and a stale one fails the validation. It
    #   fails only under MariaDB: SQLite reuses the ids freed by the rollback, so
    #   the cached authorization keeps pointing at a level id that the next
    #   example happens to create again, and the staleness cancels itself out.
    # - validating the enrollment loads its advisements, and the rules read that
    #   same collection -- without the reload it stays cached empty and every
    #   advisement rule silently misses.
    def enrollment_advised_by(professor)
      enrollment = FactoryBot.create(:enrollment)
      FactoryBot.create(
        :advisement_authorization, professor: professor, level: enrollment.level
      )
      professor.advisement_authorizations.reload
      FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
      enrollment.reload
    end

    it "changes only the enrollment requests of its own advisees" do
      advised = enrollment_advised_by(@professor)
      stranger = enrollment_advised_by(@other_professor)
      own_request = FactoryBot.create(:enrollment_request, enrollment: advised)
      other_request = FactoryBot.create(:enrollment_request, enrollment: stranger)

      expect(ability).to be_able_to(:read_advisement_pendencies, EnrollmentRequest)
      expect(ability).to be_able_to(:update, own_request)
      expect(ability).not_to be_able_to(:update, other_request)

      # Declared after the grants, so they override them even for the advisor.
      expect(ability).not_to be_able_to(:create, EnrollmentRequest)
      expect(ability).not_to be_able_to(:destroy, own_request)
    end

    it "does not reopen a class enrollment request already effected" do
      advised = enrollment_advised_by(@professor)
      own_request = FactoryBot.create(:enrollment_request, enrollment: advised)

      pending = ClassEnrollmentRequest.new(
        enrollment_request: own_request, status: ClassEnrollmentRequest::REQUESTED
      )
      effected = ClassEnrollmentRequest.new(
        enrollment_request: own_request, status: ClassEnrollmentRequest::EFFECTED
      )

      expect(ability).to be_able_to(:update, pending)
      expect(ability).not_to be_able_to(:update, effected)
    end

    # CustomVariable.professor_login_can_post_grades decides the only writes a
    # professor has over a class. Each of its three outcomes builds a different
    # set of rules, and the value is read while the Ability is being built --
    # hence the stub before the subject is first touched.
    describe "posting grades" do
      def course_class_for(professor, year:, semester:)
        CourseClass.new(professor: professor, year: year, semester: semester)
      end

      before(:each) do
        current = YearSemester.current
        @own_class = course_class_for(
          @professor, year: current.year, semester: current.semester
        )
        @own_old_class = course_class_for(@professor, year: current.year - 1, semester: 1)
        @other_class = course_class_for(
          @other_professor, year: current.year, semester: current.semester
        )
      end

      context "when it allows every semester" do
        before(:each) do
          allow(CustomVariable).to receive(:professor_login_can_post_grades)
            .and_return("yes_all_semesters")
        end

        it "posts grades on its own classes, whatever the semester" do
          expect(ability).to be_able_to(:post_grades, @own_class)
          expect(ability).to be_able_to(:post_grades, @own_old_class)
          expect(ability).to be_able_to(:read_pendencies, @own_class)
          expect(ability).to be_able_to(
            :post_grades, ClassEnrollment.new(course_class: @own_class)
          )
        end

        it "posts no grades on a class of another professor" do
          expect(ability).not_to be_able_to(:post_grades, @other_class)
          expect(ability).not_to be_able_to(
            :post_grades, ClassEnrollment.new(course_class: @other_class)
          )
        end
      end

      context "when it allows only the current semester" do
        before(:each) do
          allow(CustomVariable).to receive(:professor_login_can_post_grades)
            .and_return("yes")
        end

        it "posts grades on its own class of the current semester only" do
          expect(ability).to be_able_to(:post_grades, @own_class)
          expect(ability).to be_able_to(
            :post_grades, ClassEnrollment.new(course_class: @own_class)
          )
          expect(ability).not_to be_able_to(:post_grades, @own_old_class)
          expect(ability).not_to be_able_to(:post_grades, @other_class)
        end
      end

      context "when it does not allow it" do
        before(:each) do
          allow(CustomVariable).to receive(:professor_login_can_post_grades)
            .and_return("no")
        end

        it "reads the class and writes nothing" do
          expect(ability).to be_able_to(:read, @own_class)
          expect(ability).not_to be_able_to(:post_grades, @own_class)
          expect(ability).not_to be_able_to(:update, @own_class)
          expect(ability).not_to be_able_to(:read_pendencies, @own_class)
          expect(ability).not_to be_able_to(
            :post_grades, ClassEnrollment.new(course_class: @own_class)
          )
        end
      end
    end

    # initialize_professors builds its ownership conditions from user.professor,
    # behind an `if user.professor.present?` guard (mirroring initialize_courses).
    # Without it, a missing association degrades every condition to `professor: nil`
    # / `owner: nil`, which grants rather than denies -- and the paper rules do
    # match on a nil owner, by design, for the unsaved parent of the subform. The
    # guard is what keeps that deliberate opening from reaching a user with no
    # professor of his own. These examples pin the safe outcome: the professor
    # still reads the domain but owns nothing.
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

      it "owns no authorship row either, saved or unsaved" do
        paper = FactoryBot.create(:paper, owner: @professor)
        row = FactoryBot.create(:paper_professor, paper: paper)

        expect(ability).not_to be_able_to(:update, row)
        expect(ability).not_to be_able_to(:destroy, row)
        expect(ability).not_to be_able_to(:destroy, Paper.new.paper_professors.build)
        expect(ability).not_to be_able_to(:destroy, Paper.new.paper_students.build)
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

    # The controller authorizes with the enrollment number taken from the query
    # params, so the second argument is what separates one student from another.
    it "generates assertions only for its own enrollment numbers" do
      assertion = Assertion.new(student_can_generate: true)
      closed = Assertion.new(student_can_generate: false)

      expect(ability).to be_able_to(:assertion_pdf, Assertion)
      expect(ability).to be_able_to(
        :generate_assertion, assertion, @enrollment.enrollment_number
      )
      expect(ability).not_to be_able_to(
        :generate_assertion, assertion, @other_enrollment.enrollment_number
      )
      expect(ability).not_to be_able_to(
        :generate_assertion, closed, @enrollment.enrollment_number
      )
    end

    context "when the role is set but no student record is linked" do
      subject(:ability) { ability_for(Role::ROLE_ALUNO) }

      it "is denied the student pages" do
        expect(ability).not_to be_able_to(:show, :student_enrollment)
        expect(ability).not_to be_able_to(:enroll, :student_enrollment)
      end

      # The guard sits on the whole ROLE_ALUNO branch of initialize_documents,
      # so :assertion_pdf goes with it. That is what AssertionsController checks
      # first, through authorize_resource: denying it turns what would be a
      # NoMethodError inside the :generate_assertion block into a clean refusal.
      it "cannot generate assertions and does not raise" do
        assertion = Assertion.new(student_can_generate: true)

        expect(ability).not_to be_able_to(:assertion_pdf, Assertion)
        expect(ability).not_to be_able_to(:generate_assertion, assertion)
        expect(ability).not_to be_able_to(:generate_assertion, assertion, "M1")
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

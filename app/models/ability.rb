# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Ability
  include CanCan::Ability
  include Admissions::Ability

  STUDENT_MODELS = [
    Student, Dismissal, Enrollment, EnrollmentHold, Level, DismissalReason,
    EnrollmentStatus,
    StudentMajor
  ]

  PROFESSOR_MODELS = [
    Professor, Advisement, AdvisementAuthorization,
    ThesisDefenseCommitteeParticipation,
    ProfessorResearchArea, Grant, Paper, PaperProfessor, PaperStudent
  ]

  SCHOLARSHIP_MODELS = [
    Sponsor, ScholarshipDuration, Scholarship, ScholarshipType,
    ScholarshipSuspension,
  ]

  PHASE_MODELS = [
    Deferral, Accomplishment, Phase, DeferralType,
    PhaseCompletion, PhaseDuration,
  ]

  COURSE_MODELS = [
    ResearchArea, Course, CourseType, CourseClass, ClassSchedule,
    ClassEnrollment, Allocation, EnrollmentRequest, ClassEnrollmentRequest,
    EnrollmentRequestComment,
  ]

  EDUCATION_MODELS = [
    Major, Institution,
  ]

  DOCUMENT_MODELS = [
    Report, Assertion, Notification, NotificationLog, ReportConfiguration, Query
  ]

  PLACE_MODELS = [
    City, State, Country
  ]

  CONFIGURATION_MODELS = [
    User, Role, Version, EmailTemplate,
    CustomVariable, YearSemester
  ]

  def initialize(user)
    alias_action :list, :row, :show_search, :render_field, :class_schedule_pdf,
      :to_pdf, :summary_pdf, :academic_transcript_pdf, :grades_report_pdf,
      :browse, :simulate, :set_query_date, :cities, :states,
      :preview, :builtin, :help, :generate_assertion, to: :read
    alias_action :update_column, :edit_associated, :new_existing, :add_existing,
      :duplicate, to: :update
    alias_action :delete, :destroy_existing, to: :destroy
    alias_action :override_signature_grades_report_pdf, :override_signature_transcript_pdf,
                :override_signature_assertion_pdf, to: :override_report_signature_type
    user ||= User.new

    role_id = user.role_id
    roles = { role_id => true }
    roles[:manager] = (
      roles[Role::ROLE_ADMINISTRADOR] ||
      roles[Role::ROLE_COORDENACAO] ||
      roles[Role::ROLE_SECRETARIA]
    )

    if roles[Role::ROLE_ADMINISTRADOR]
      can :manage, :all
    end
    if roles[:manager] || roles[Role::ROLE_PROFESSOR] || roles[Role::ROLE_SUPORTE]
      can :read, :pendency
    end

    initialize_students(user, roles)
    initialize_professors(user, roles)
    initialize_scholarships(user, roles)
    initialize_phases(user, roles)
    initialize_courses(user, roles)
    initialize_education(user, roles)
    initialize_documents(user, roles)
    initialize_places(user, roles)
    initialize_admissions(user, roles)
    initialize_configurations(user, roles)
    initialize_student_pages(user, roles)

    can :read, :landing
    can :notify, Notification
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end

  def initialize_students(user, roles)
    if roles[:manager]
      can :manage, Ability::STUDENT_MODELS
      can :update_all_fields, Student
      can :read_all_fields, Student
      can :override_report_signature_type, Enrollment
      can :generate_report_without_watermark, Enrollment
      can :invite, User
    end
    if roles[Role::ROLE_PROFESSOR]
      can :read, Ability::STUDENT_MODELS
      can :read_all_fields, Student
      can :photo, Student
    end
    if roles[Role::ROLE_SUPORTE]
      can [:read, :update, :update_only_photo], (Student)
    end

    # Keep this at the end or :read STUDENT_MODELS will override it
    cannot :academic_transcript_pdf, Enrollment do |enrollment|
      enrollment.dismissal&.dismissal_reason&.thesis_judgement != DismissalReason::APPROVED
    end unless roles[:manager]
  end

  def initialize_professors(user, roles)
    if roles[:manager]
      can :manage, Ability::PROFESSOR_MODELS
    end
    if roles[Role::ROLE_PROFESSOR]
      can :read, Ability::PROFESSOR_MODELS
      cannot :edit_professor, Grant
      cannot :edit_professor, Paper
      can :create, Grant
      can :update, Grant, professor: user.professor
      can :destroy, Grant, professor: user.professor
      can :create, Paper
      can :update, Paper, owner: user.professor
      can :create, PaperProfessor
      can :create, PaperStudent
      can :update, PaperProfessor, paper: { owner: user.professor }
      can :update, PaperStudent, paper: { owner: user.professor }
      can :destroy, PaperProfessor, paper: { owner: user.professor }
      can :destroy, PaperStudent, paper: { owner: user.professor }
      can :destroy, PaperProfessor, paper: { owner: nil }
      can :destroy, PaperStudent, paper: { owner: nil }
      can :destroy, Paper, owner: user.professor
    end
  end

  def initialize_scholarships(user, roles)
    if roles[:manager]
      can :manage, Ability::SCHOLARSHIP_MODELS
    end
    if roles[Role::ROLE_PROFESSOR]
      can :read, Ability::SCHOLARSHIP_MODELS
    end
  end

  def initialize_phases(user, roles)
    if roles[:manager]
      can :manage, Ability::PHASE_MODELS
    end
    if roles[Role::ROLE_PROFESSOR]
      can :read, Ability::PHASE_MODELS
    end
  end

  def initialize_courses(user, roles)
    alias_action :set_invalid, :set_requested, :set_valid, to: :update
    alias_action :set_effected, :show_effect, to: :effect
    if roles[:manager]
      can :manage, Ability::COURSE_MODELS
      can :update_all_fields, ClassEnrollment
      can :update_all_fields, CourseClass
      if !roles[Role::ROLE_COORDENACAO] && !roles[Role::ROLE_SECRETARIA]
        cannot :read_pendencies, ClassEnrollmentRequest
      end
    end
    if roles[Role::ROLE_PROFESSOR]
      can :read, Ability::COURSE_MODELS
      if user.professor.present?
        can :read_advisement_pendencies, EnrollmentRequest
        can :update, EnrollmentRequest, enrollment: {
          advisements: { professor: user.professor }
        }
        can :update, ClassEnrollmentRequest, enrollment_request: {
          enrollment: { advisements: { professor: user.professor } }
        }
        cannot :update, ClassEnrollmentRequest,
          status: ClassEnrollmentRequest::EFFECTED if !roles[:manager]

        if CustomVariable.professor_login_can_post_grades == "yes_all_semesters"
          can [:update, :post_grades], ClassEnrollment, course_class: {
            professor: user.professor
          }
          can [:update, :post_grades], CourseClass, professor: user.professor
        elsif CustomVariable.professor_login_can_post_grades == "yes"
          can [:update, :post_grades], ClassEnrollment, course_class: {
            professor: user.professor,
            year: YearSemester.current.year,
            semester: YearSemester.current.semester
          }
          can [:update, :post_grades], CourseClass,
            professor: user.professor,
            year: YearSemester.current.year,
            semester: YearSemester.current.semester
        end
      end
    else
      cannot [:read_advisement_pendencies, :read_pendencies], EnrollmentRequest
    end
    cannot [:create, :destroy], EnrollmentRequest
    cannot [:create, :destroy], ClassEnrollmentRequest
  end

  def initialize_education(user, roles)
    if roles[:manager]
      can :manage, Ability::EDUCATION_MODELS
    end
    if roles[Role::ROLE_PROFESSOR]
      can :read, Ability::EDUCATION_MODELS
    end
  end

  def initialize_documents(user, roles)
    alias_action :execute_now, :execute_now, :notify, to: :update
    if roles[:manager]
      can :manage, Ability::DOCUMENT_MODELS
    end
    if roles[Role::ROLE_SECRETARIA]
      cannot :read, [ReportConfiguration]
      cannot [:destroy, :update, :create], [Assertion, Query, Notification]
    end
    if roles[Role::ROLE_COORDENACAO]
      cannot :manage, ReportConfiguration
    end
    # Voltar essas permissões assim que alunos puderem gerar seus próprios documentos
    # if roles[Role::ROLE_ALUNO]
    #   can :assertion_pdf, Assertion
    #   can :generate_assertion, Assertion do |assertion, matricula_aluno|
    #     assertion.student_can_generate && matricula_aluno.in?(user.student.enrollments.pluck(:enrollment_number))
    #   end
    # end
    if roles[Role::ROLE_PROFESSOR]
      can :assertion_pdf, Assertion
      # Voltar junto com a permissão dos alunos
      # can :generate_assertion, Assertion do |assertion|
      #   assertion.student_can_generate
      # end
    end
    cannot [:destroy, :update, :create], NotificationLog
  end

  def initialize_places(user, roles)
    if roles[:manager]
      can :manage, Ability::PLACE_MODELS
    end
  end

  def initialize_configurations(user, roles)
    alias_action :execute_now, :execute_now, :notify, to: :update
    if roles[Role::ROLE_COORDENACAO]
      can :manage, (Ability::CONFIGURATION_MODELS - [
        CustomVariable
      ])
    end
    if roles[Role::ROLE_SECRETARIA]
      can :read, (Version)
    end
    cannot [:destroy, :update, :create], Role
    cannot [:destroy, :update, :create], Version
  end

  def initialize_student_pages(user, roles)
    if roles.include?(Role::ROLE_ALUNO) && user.student.present?
      can [:show, :enroll, :save_enroll], :student_enrollment
      # Voltar essas permissões assim que alunos puderem gerar seus próprios documentos
      # can :academic_transcript_pdf, Enrollment do |enrollment|
      #   enrollment.dismissal&.dismissal_reason&.thesis_judgement === DismissalReason::APPROVED && enrollment.student_id === user.student.id
      # end
      # can :grades_report_pdf, Enrollment, student_id: user.student.id
    else
      cannot [:show, :enroll, :save_enroll], :student_enrollment
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Ability
  include CanCan::Ability

  ALL_MODELS = [
    # Students
    Student, Dismissal, Enrollment, EnrollmentHold, Level, DismissalReason,
    EnrollmentStatus,
    StudentMajor,
    # Professors
    Professor, Advisement, AdvisementAuthorization,
    ThesisDefenseCommitteeParticipation,
    ProfessorResearchArea,
    # Scholarships
    Sponsor, ScholarshipDuration, Scholarship, ScholarshipType,
    ScholarshipSuspension,
    # Phases
    Deferral, Accomplishment, Phase, DeferralType,
    PhaseCompletion, PhaseDuration,
    # Courses
    ResearchArea, Course, CourseType, CourseClass, ClassSchedule,
    ClassEnrollment, Allocation, EnrollmentRequest, ClassEnrollmentRequest,
    EnrollmentRequestComment,
    # Educations
    Major, Institution,
    # Places
    City, State, Country,
    # Configurations
    User, Role, Version, Notification, EmailTemplate, Query, NotificationLog,
    CustomVariable, ReportConfiguration,
    YearSemester,
    # Application Process
    Admissions::FormTemplate, Admissions::FormField,
    Admissions::FilledForm, Admissions::FilledFormField,
    Admissions::AdmissionProcess, Admissions::AdmissionApplication,
    Admissions::LetterRequest,
  ]


  def initialize(user)
    alias_action :list, :row, :show_search, :render_field, :class_schedule_pdf,
      :to_pdf, :summary_pdf, :academic_transcript_pdf, :grades_report_pdf,
      :browse, :simulate, :set_query_date, :cities, :states,
      :preview, :builtin, :help, to: :read
    alias_action :update_column, :edit_associated, :new_existing, :add_existing,
      :execute_now, :execute_now, :notify, :duplicate, to: :update
    alias_action :delete, :destroy_existing, to: :destroy
    alias_action :set_invalid, :set_requested, :set_valid, to: :update
    alias_action :ser_effected, :show_effect, to: :effect

    user ||= User.new

    role_id = user.role_id

    if role_id == Role::ROLE_ADMINISTRADOR
      can :manage, :all
      cannot :update_only_photo, Student
      cannot [:show, :enroll, :save_enroll], :student_enrollment
      cannot [:read_advisement_pendencies, :read_pendencies], EnrollmentRequest
      cannot [:read_pendencies], ClassEnrollmentRequest
      cannot [:destroy, :update, :create], Role
    elsif role_id == Role::ROLE_COORDENACAO
      can :manage, (Ability::ALL_MODELS - [
        Role, CustomVariable, ReportConfiguration,
        Admissions::FormTemplate, Admissions::FormField,
        Admissions::FilledForm, Admissions::FilledFormField,
        Admissions::AdmissionProcess, Admissions::AdmissionApplication,
        Admissions::LetterRequest
      ])
      cannot :update_only_photo, Student
      can :read, :pendency
      cannot [:read_advisement_pendencies, :read_pendencies], EnrollmentRequest
      can :read, (Role)
    elsif role_id == Role::ROLE_PROFESSOR
      can :read, (Ability::ALL_MODELS - [
        User, Role, CustomVariable, Query, Version,
        Notification, NotificationLog, ReportConfiguration,
        Country, State, City, EmailTemplate,
        Admissions::FormTemplate, Admissions::FormField,
        Admissions::FilledForm, Admissions::FilledFormField,
        Admissions::AdmissionProcess, Admissions::AdmissionApplication,
        Admissions::LetterRequest
      ])
      can :photo, Student
      can :read, :pendency
      if user.professor
        can :read_advisement_pendencies, EnrollmentRequest
        can :update, EnrollmentRequest, enrollment: {
          advisements: { professor: user.professor }
        }
        can :update, ClassEnrollmentRequest, enrollment_request: {
          enrollment: { advisements: { professor: user.professor } }
        }
        cannot :update, ClassEnrollmentRequest,
          status: ClassEnrollmentRequest::EFFECTED
        if CustomVariable.professor_login_can_post_grades == "yes_all_semesters"
          can :update, ClassEnrollment, course_class: {
            professor: user.professor
          }
          can :update, CourseClass, professor: user.professor
        elsif CustomVariable.professor_login_can_post_grades == "yes"
          can :update, ClassEnrollment, course_class: {
            professor: user.professor,
            year: YearSemester.current.year,
            semester: YearSemester.current.semester
          }
          can :update, CourseClass,
            professor: user.professor,
            year: YearSemester.current.year,
            semester: YearSemester.current.semester
        end
      end
    elsif role_id == Role::ROLE_SECRETARIA
      can :manage, (Ability::ALL_MODELS - [
        User, Role, CustomVariable, Query, Version,
        Notification, ReportConfiguration,
        Admissions::FormTemplate, Admissions::FormField,
        Admissions::FilledForm, Admissions::FilledFormField,
        Admissions::AdmissionProcess, Admissions::AdmissionApplication,
        Admissions::LetterRequest
      ])
      cannot :update_only_photo, Student
      can :invite, User
      can :read, :pendency
      cannot [:read_advisement_pendencies, :read_pendencies], EnrollmentRequest
      can [:read, :execute], (Query)
    elsif role_id == Role::ROLE_SUPORTE
      can [:read, :update, :update_only_photo], (Student)
      can :read, :pendency
    elsif role_id == Role::ROLE_ALUNO
      can :manage, []
      can [:show, :enroll, :save_enroll], :student_enrollment if
        user.present? && user.student.present?
    elsif role_id == Role::ROLE_DESCONHECIDO
      can :manage, []
    end
    can :read, :landing
    can :notify, Notification
    can :download, Admissions::FilledFormField

    # Admissions
    can :manage, ActiveScaffoldWorkaround
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
end

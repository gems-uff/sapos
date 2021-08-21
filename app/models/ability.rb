# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Ability
  include CanCan::Ability

  ALL_MODELS = [Accomplishment, Advisement, AdvisementAuthorization, Allocation,
                City, ClassEnrollment, ClassEnrollmentRequest, ClassSchedule, Country, Course, CourseClass, CourseType,
                CustomVariable, Deferral, DeferralType, Dismissal, 
                DismissalReason, Enrollment, EnrollmentHold, EnrollmentRequest, EnrollmentStatus, 
                Institution, Level, Major, Notification, NotificationLog, Phase, 
                PhaseCompletion, PhaseDuration, Professor, ProfessorResearchArea,
                Query, ReportConfiguration, ResearchArea, Role, Scholarship, ScholarshipDuration, 
                ScholarshipSuspension, ScholarshipType, Sponsor, State, Student, StudentMajor, 
                ThesisDefenseCommitteeParticipation, User, Version, YearSemester] 


  def initialize(user)
    alias_action :list, :row, :show_search, :render_field, :class_schedule_pdf,
        :to_pdf, :summary_pdf, :academic_transcript_pdf, :grades_report_pdf, 
        :browse, :simulate, :set_query_date, :cities, :states, :preview, :to => :read
    alias_action :update_column, :edit_associated, :new_existing, :add_existing, 
        :execute_now, :execute_now, :notify, :duplicate, :to => :update
    alias_action :delete, :destroy_existing, :to => :destroy
    #as_action_aliases

    user ||= User.new

    role_id = user.role_id

    if role_id == Role::ROLE_ADMINISTRADOR
      can :manage, :all
      can :invite, User
      can :read, :pendencies
      cannot [:destroy, :update], Role
      cannot [:destroy, :create], NotificationParam
    elsif role_id == Role::ROLE_COORDENACAO
      can :manage, (Ability::ALL_MODELS - [Role, CustomVariable, ReportConfiguration])
      can :read, :pendencies
      can :invite, User
      can :read, (Role)
    elsif role_id == Role::ROLE_PROFESSOR
      can :read, (Ability::ALL_MODELS - [User, Role, CustomVariable, Query, Version, Notification, NotificationLog, ReportConfiguration, ClassSchedule])
      can :read, :pendencies
      if user.professor
        if CustomVariable.professor_login_can_post_grades == "yes_all_semesters"
          can :update, ClassEnrollment, course_class: { professor: user.professor }
          can :update, CourseClass, professor: user.professor
        elsif CustomVariable.professor_login_can_post_grades == "yes"
          can :update, ClassEnrollment, course_class: { professor: user.professor, year: YearSemester.current.year, semester: YearSemester.current.semester }
          can :update, CourseClass, professor: user.professor, year: YearSemester.current.year, semester: YearSemester.current.semester
        end
      end
    elsif role_id == Role::ROLE_SECRETARIA
      can :manage, (Ability::ALL_MODELS - [User, Role, CustomVariable, Query, Version, Notification, ReportConfiguration])
      can :read, :pendencies
      can :read, (Query)
    elsif role_id == Role::ROLE_SUPORTE
      can [:read, :update, :photo], (Student)
      can :read, :pendencies
    elsif role_id == Role::ROLE_ALUNO
      #can :read, :landing
      can :manage, []
    elsif role_id == Role::ROLE_DESCONHECIDO
      can :manage, []
    end
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
end

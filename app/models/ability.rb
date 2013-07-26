# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Ability
  include CanCan::Ability

  ALL_MODELS = [Accomplishment, Advisement, AdvisementAuthorization, Allocation,
                City, ClassEnrollment, Country, Course, CourseClass, CourseType,
                Deferral, DeferralType, Dismissal, DismissalReason, Enrollment,
                EnrollmentStatus, Institution, Level, Major, Phase, PhaseDuration,
                Professor, ProfessorResearchArea, ResearchArea, Role, Scholarship,
                ScholarshipDuration, ScholarshipType, Sponsor, State, Student,
                User, YearSemester]


  def initialize(user)
    alias_action :list, :row, :show_search, :render_field, :to_pdf, :to => :read
    alias_action :update_column, :edit_associated, :new_existing, :add_existing, :to => :update
    alias_action :delete, :destroy_existing, :to => :destroy
    #as_action_aliases

    user ||= User.new

    role_id = user.role_id


    if role_id == Role::ROLE_ADMINISTRADOR
      can :manage, :all
    elsif role_id == Role::ROLE_COORDENACAO
      can :manage, :all
    elsif role_id == Role::ROLE_PROFESSOR
      can :read, (Ability::ALL_MODELS - [User, Role])
      can :summary_pdf, CourseClass
      can :academic_transcript_pdf, Enrollment
      can :grades_report_pdf, Enrollment
    elsif role_id == Role::ROLE_SECRETARIA
      can :manage, (Ability::ALL_MODELS - [User, Role])
      can :summary_pdf, CourseClass
      can :academic_transcript_pdf, Enrollment
      can :grades_report_pdf, Enrollment
    end

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

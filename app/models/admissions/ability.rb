# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::Ability

  ADMISSION_PROCESS_CONFIG = [
    Admissions::AdmissionProcess,
    Admissions::AdmissionProcessPhase,
  ]

  ADMISSION_FORM_CONFIG = [
    Admissions::FormTemplate, Admissions::FormField,
  ]

  ADMISSION_COMMITTEE = [
    Admissions::AdmissionCommitteeMember, Admissions::AdmissionCommittee,
  ]

  ADMISSION_PHASE = [
    Admissions::AdmissionPhase,
    Admissions::AdmissionPhaseCommittee,
    Admissions::FormCondition
  ]

  ADMISSION_FILLED_MODELS = [
    Admissions::FilledForm, Admissions::FilledFormField,
    Admissions::FilledFormFieldScholarity,
    Admissions::LetterRequest,
  ]

  ADMISSION_FORM_EVALUATION = [
    Admissions::AdmissionPhaseEvaluation, Admissions::AdmissionPhaseResult
  ]

  ADMISSION_APPLICATION = [
    Admissions::AdmissionApplication, Admissions::AdmissionPendency
  ] + ADMISSION_FILLED_MODELS + ADMISSION_FORM_EVALUATION

  ADMISSION_RANKING = [
    Admissions::RankingConfig,
    Admissions::RankingColumn,
    Admissions::RankingGroup,
    Admissions::RankingMachine,
    Admissions::RankingProcess,
    Admissions::AdmissionProcessRanking,
  ]

  ADMISSION_RANKING_RESULT = [
    Admissions::AdmissionRankingResult,
  ]

  ADMISSION_REPORT = [
    Admissions::AdmissionReportConfig,
    Admissions::AdmissionReportGroup,
    Admissions::AdmissionReportColumn,
  ]

  ADMISSION_MODELS = (
    ADMISSION_PROCESS_CONFIG +
    ADMISSION_FORM_CONFIG +
    ADMISSION_COMMITTEE +
    ADMISSION_PHASE +
    ADMISSION_APPLICATION +
    ADMISSION_RANKING +
    ADMISSION_RANKING_RESULT +
    ADMISSION_REPORT
  )

  def initialize_admissions(user, roles)
    alias_action :map_student_form, :map_student_form_create_update, to: :map_student
    if roles[:manager]
      can :undo_consolidation, Admissions::AdmissionApplication
      can :override, Admissions::AdmissionApplication
      can :cancel, Admissions::AdmissionApplication
      can :configuration, Admissions::AdmissionApplication
      can :read_all, Admissions::AdmissionApplication
      can :map_student, Admissions::AdmissionApplication
    end
    if roles[Role::ROLE_ADMINISTRADOR] || roles[Role::ROLE_COORDENACAO]
      can :manage, ADMISSION_MODELS
    end
    if roles[Role::ROLE_SECRETARIA]
      can :manage, ADMISSION_PROCESS_CONFIG
      can :read, ADMISSION_FORM_CONFIG
      can :manage, ADMISSION_COMMITTEE
      can [:read, :update], Admissions::AdmissionApplication
      can :read, ADMISSION_FILLED_MODELS
      can [:read, :destroy], ADMISSION_FORM_EVALUATION
      can :manage, ADMISSION_RANKING
      can [:read, :destroy], ADMISSION_RANKING_RESULT
      can :manage, ADMISSION_REPORT
    end
    if roles[Role::ROLE_PROFESSOR]
      can :browse, Admissions::AdmissionProcess
      can :browse, Admissions::AdmissionPhase
      can :browse, Admissions::AdmissionReportConfig

      application_condition = {
        pendencies: {
          user_id: user.id
        }
      }
      can :read_pendencies, Admissions::AdmissionApplication
      can :read, Admissions::AdmissionApplication, application_condition
      can :update, Admissions::AdmissionApplication, application_condition
      # A possible bug in cancan is preventing the following check due to a conflict
      # with the other FilledForm permissions
      # Since the only usage of direct filled_form -> application usage is available
      # under manual queries inside edit and show candidate, we can safely remove
      # the check without preventing professors from reading filled forms
      # can :read, Admissions::FilledForm,
      #  admission_application: application_condition
      can :read, Admissions::LetterRequest,
        admission_application: application_condition
      can :read, Admissions::FilledForm, letter_request: {
        admission_application: application_condition
      }
      can :read, Admissions::AdmissionPhaseEvaluation, user: user
      can :read, Admissions::FilledForm, admission_phase_evaluation: {
        user: user
      }
      can :read, Admissions::AdmissionPhaseResult,
        admission_application: application_condition
      can :read, Admissions::FilledForm, admission_phase_result: {
        admission_application: application_condition
      }
      can :read, Admissions::AdmissionRankingResult,
        admission_application: application_condition
      can :read, Admissions::FilledForm, admission_ranking_result: {
        admission_application: application_condition
      }
    end

    cannot :create, Admissions::AdmissionApplication
    cannot [:create, :update, :destroy], Admissions::AdmissionPendency
    cannot [:create, :update, :destroy], ADMISSION_FILLED_MODELS
    cannot [:create, :update], ADMISSION_FORM_EVALUATION

    can :download, Admissions::FilledFormField
    can :manage, ActiveScaffoldWorkaround
  end
end
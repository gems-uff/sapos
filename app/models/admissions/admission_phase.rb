# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhase < ActiveRecord::Base
  has_paper_trail

  has_many :admission_phase_committees, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseCommittee"
  has_many :admission_committees, through: :admission_phase_committees,
    class_name: "Admissions::AdmissionCommittee"
  has_many :admission_phase_results, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseResult"
  has_many :admission_phase_evaluations, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"
  has_many :admission_process_phases, dependent: :destroy,
    class_name: "Admissions::AdmissionProcessPhase"
  has_many :admission_applications, dependent: :destroy,
    class_name: "Admissions::AdmissionApplication"
  has_many :admission_pendencies, dependent: :destroy,
    class_name: "Admissions::AdmissionPendency"
  has_many :admission_process_rankings, dependent: :nullify,
    class_name: "Admissions::AdmissionProcessRanking"

  belongs_to :approval_condition, optional: true,
    class_name: "Admissions::FormCondition", foreign_key: "approval_condition_id"
  belongs_to :keep_in_phase_condition, optional: true,
    class_name: "Admissions::FormCondition", foreign_key: "keep_in_phase_condition_id"
  belongs_to :member_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "member_form_id"
  belongs_to :shared_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "shared_form_id"
  belongs_to :consolidation_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "consolidation_form_id"
  belongs_to :candidate_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "candidate_form_id"

  validates :name, presence: true
  after_commit :update_pendencies

  accepts_nested_attributes_for :approval_condition,
    reject_if: :all_blank,
    allow_destroy: true


  def to_label
    "#{self.name}"
  end

  def initialize_dup(other)
    super
    self.admission_phase_committees = other.admission_phase_committees.map(&:dup)
    self.approval_condition = other.approval_condition.dup
  end

  def committee_users_for_candidate(candidate, should_raise: nil)
    users = {}
    self.admission_committees.each do |committee|
      if candidate.satisfies_condition(committee.form_condition, should_raise: should_raise)
        committee.users.each { |user| users[user.id] = user }
      end
    end
    users
  end

  def update_pendencies
    self.admission_applications.non_consolidated.each do |candidate|
      create_pendencies_for_candidate(candidate)
    end
  end

  def create_pendencies_for_candidate(candidate, should_raise: nil)
    users = self.committee_users_for_candidate(candidate, should_raise: should_raise)

    pendencies = []
    pendencies = pendencies.concat(Admissions::AdmissionPendency.candidate_pendencies(
      self, candidate
    )) if self.candidate_form.present?
    pendencies = pendencies.concat(Admissions::AdmissionPendency.member_pendencies(
      self, candidate, users
    )) if self.member_form.present?
    pendencies = pendencies.concat(Admissions::AdmissionPendency.shared_pendencies(
      self, candidate, users
    )) if self.shared_form.present?

    # Remove all other pendencies
    Admissions::AdmissionPendency
      .where(admission_application_id: candidate.id, admission_phase_id: self.id)
      .where.not(id: pendencies)
      .delete_all
    users.present?
  end

  def prepare_application_forms(
    admission_application,
    can_edit_override: false,
    check_candidate_permission: false,
    committee_permission_user: nil
  )
    end_status = Admissions::AdmissionApplication::END_OF_PHASE_STATUSES
    result = {}
    current_phase = admission_application.admission_phase
    latest_available_phase = self.id == current_phase.try(:id)
    during_latest_phase = (
      latest_available_phase &&
      !end_status.include?(admission_application.status)
    )
    create_consolidation = !during_latest_phase
    can_edit_phase = can_edit_override || during_latest_phase

    phase_forms = []
    if self.shared_form.present?
      object = admission_application.results.filter do |object|
        object.admission_phase_id == self.id &&
          object.mode == Admissions::AdmissionPhaseResult::SHARED
      end[0]
      from_build = false
      if object.nil?
        object = admission_application.results.build(
          admission_phase_id: self.id,
          mode: Admissions::AdmissionPhaseResult::SHARED
        )
        from_build = true
      end
      object.filled_form.prepare_missing_fields
      phase_forms << {
        name: Admissions::AdmissionPendency::SHARED,
        mode: :shared,
        object:,
        from_build:,
        field: :results,
        form_template: self.shared_form,
        hidden: [:id, :admission_phase_id, :mode],
        pendency_success: {
          admission_application_id: admission_application.id,
          admission_phase_id: self.id,
          mode: Admissions::AdmissionPendency::SHARED,
        },
      }
    end
    if self.candidate_form.present?
      object = admission_application.results.filter do |object|
        object.admission_phase_id == self.id &&
          object.mode == Admissions::AdmissionPhaseResult::CANDIDATE
      end[0]
      from_build = false
      if object.nil?
        object = admission_application.results.build(
          admission_phase_id: self.id,
          mode: Admissions::AdmissionPhaseResult::CANDIDATE
        )
        from_build = true
      end
      object.filled_form.prepare_missing_fields
      phase_forms << {
        name: Admissions::AdmissionPendency::CANDIDATE,
        mode: :candidate,
        object:,
        from_build:,
        field: :results,
        form_template: self.candidate_form,
        hidden: [:id, :admission_phase_id, :mode],
        pendency_success: {
          admission_application_id: admission_application.id,
          admission_phase_id: self.id,
          mode: Admissions::AdmissionPendency::CANDIDATE,
        },
      }
    end
    if self.member_form.present?
      member_ids = admission_application.pendencies.where(
        mode: Admissions::AdmissionPendency::MEMBER,
        admission_phase_id: self.id
      ).distinct.pluck(:user_id).compact
      member_ids.each do |member_id|
        object = admission_application.evaluations.filter do |object|
          object.admission_phase_id == self.id &&
            object.user_id == member_id
        end[0]
        from_build = false
        if object.nil?
          object = admission_application.evaluations.build(
            admission_phase_id: self.id,
            user_id: member_id
          )
          from_build = true
        end
        object.filled_form.prepare_missing_fields
        phase_forms << {
          name: User.where(id: member_id).pluck(:name).first,
          mode: :member,
          object:,
          from_build:,
          field: :evaluations,
          form_template: self.member_form,
          hidden: [:id, :admission_phase_id, :user_id],
          user_id: member_id,
          pendency_success: {
            admission_application_id: admission_application.id,
            admission_phase_id: self.id,
            mode: Admissions::AdmissionPendency::MEMBER,
            user_id: member_id,
          },
        }
      end
    end
    if self.consolidation_form.present?
      object = admission_application.results.filter do |object|
        object.admission_phase_id == self.id &&
          object.mode == Admissions::AdmissionPhaseResult::CONSOLIDATION
      end[0]
      from_build = false
      if object.nil? && create_consolidation
        object = admission_application.results.build(
          admission_phase_id: self.id,
          mode: Admissions::AdmissionPhaseResult::CONSOLIDATION
        )
        from_build = true
      end
      if object.present?
        object.filled_form.prepare_missing_fields
        phase_forms << {
          name: Admissions::AdmissionPhaseResult::CONSOLIDATION,
          mode: :consolidation,
          object:,
          from_build:,
          field: :results,
          form_template: self.consolidation_form,
          hidden: [:id, :admission_phase_id, :mode],
          pendency_success: nil,
        }
      end
    end
    result[:latest_available_phase] = latest_available_phase
    result[:phase_forms] = phase_forms.filter do |phase_form|
      can_edit_form = can_edit_phase
      if check_candidate_permission
        next false if phase_form[:mode] == :shared && !self.candidate_can_see_shared
        next false if phase_form[:mode] == :member && !self.candidate_can_see_member
        next false if phase_form[:mode] == :consolidation && !self.candidate_can_see_consolidation
        can_edit_form = (
          can_edit_phase ||
          admission_application.can_edit_itself
        ) && (phase_form[:mode] == :candidate)
      end
      if committee_permission_user.present?
        next false if phase_form[:mode] == :member && phase_form[:user_id] != committee_permission_user.id
        if phase_form[:mode] == :candidate
          can_edit_form = can_edit_override || current_phase.try(:can_edit_candidate)
        end
      end
      phase_form[:can_edit_form] = can_edit_form
      true
    end
    result
  end
end

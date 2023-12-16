# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhase < ActiveRecord::Base
  has_paper_trail

  has_many :admission_phase_committees, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseCommittee"
  has_many :admission_committees, through: :admission_phase_committees,
    class_name: "Admissions::AdmissionCommittee"
  has_many :form_conditions, as: :model, dependent: :destroy,
    class_name: "Admissions::FormCondition"
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

  belongs_to :member_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "member_form_id"
  belongs_to :shared_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "shared_form_id"
  belongs_to :consolidation_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "consolidation_form_id"

  validates :name, presence: true
  after_commit :update_pendencies

  def to_label
    "#{self.name}"
  end

  def initialize_dup(other)
    super
    self.admission_phase_committees = other.admission_phase_committees.map(&:dup)
    self.form_conditions = other.form_conditions.map(&:dup)
  end

  def committee_users_for_candidate(candidate, should_raise: nil)
    users = {}
    self.admission_committees.each do |committee|
      if candidate.satisfies_conditions(committee.form_conditions, should_raise: should_raise)
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
    pendency_arel = Admissions::AdmissionPendency.arel_table
    # Remove pendencies from users that are not valid for candidate
    Admissions::AdmissionPendency.where(
      pendency_arel[:admission_application_id].eq(candidate.id)
      .and(pendency_arel[:admission_phase_id].eq(self.id))
      .and(pendency_arel[:user_id].not_in(users.keys))
    ).delete_all

    # Prepare create commands
    create_commands = []
    base_command = {
      admission_application_id: candidate.id,
      admission_phase_id: self.id,
    }
    share_command = base_command.merge(mode: Admissions::AdmissionPendency::SHARED)
    member_command = base_command.merge(mode: Admissions::AdmissionPendency::MEMBER)
    if self.shared_form.present?
      create_commands << share_command
    else
      Admissions::AdmissionPendency.where(share_command).delete_all
    end
    if self.member_form.present?
      create_commands << member_command
    else
      Admissions::AdmissionPendency.where(member_command).delete_all
    end

    # Create pendencies for users
    if users.empty?
      create_commands.each do |cmd|
        Admissions::AdmissionPendency.find_or_create_by(cmd.merge(user_id: nil))
      end
      return false  # No committee for user
    end
    Admissions::AdmissionPendency.where(
      pendency_arel[:admission_application_id].eq(candidate.id)
      .and(pendency_arel[:admission_phase_id].eq(self.id))
      .and(pendency_arel[:user_id].eq(nil))
    ).delete_all

    users.each do |uid, user|
      create_commands.each do |cmd|
        Admissions::AdmissionPendency.find_or_create_by(cmd.merge(user_id: uid))
      end
    end
    true
  end

  def prepare_application_forms(admission_application, user, create_consolidation)
    phase_forms = []
    if self.shared_form.present?
      object = admission_application.results.filter do |object|
        object.admission_phase_id == self.id &&
          object.mode == Admissions::AdmissionPhaseResult::SHARED
      end[0] || admission_application.results.build(
        admission_phase_id: self.id,
        mode: Admissions::AdmissionPhaseResult::SHARED
      )
      object.filled_form.prepare_missing_fields
      phase_forms << {
        name: Admissions::AdmissionPendency::SHARED,
        object: object,
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
    if self.member_form.present?
      user_has_member_form = self.admission_committees.any? do |committee|
        committee.members.where(user_id: user.id).first.present?
      end
      if user_has_member_form
        object = admission_application.evaluations.filter do |object|
          object.admission_phase_id == self.id &&
            object.user_id == user.id
        end[0] || admission_application.evaluations.build(
          admission_phase_id: self.id,
          user_id: user.id
        )
        object.filled_form.prepare_missing_fields
        phase_forms << {
          name: Admissions::AdmissionPendency::MEMBER,
          object: object,
          field: :evaluations,
          form_template: self.member_form,
          hidden: [:id, :admission_phase_id, :user_id],
          pendency_success: {
            admission_application_id: admission_application.id,
            admission_phase_id: self.id,
            mode: Admissions::AdmissionPendency::MEMBER,
            user_id: user.id,
          },
        }
      end
    end
    if create_consolidation && self.consolidation_form.present?
      object = admission_application.results.filter do |object|
        object.admission_phase_id == self.id &&
          object.mode == Admissions::AdmissionPhaseResult::CONSOLIDATION
      end[0] || admission_application.results.build(
        admission_phase_id: self.id,
        mode: Admissions::AdmissionPhaseResult::CONSOLIDATION
      )
      object.filled_form.prepare_missing_fields
      phase_forms << {
        name: Admissions::AdmissionPhaseResult::CONSOLIDATION,
        object: object,
        field: :results,
        form_template: self.consolidation_form,
        hidden: [:id, :admission_phase_id, :mode],
        pendency_success: nil,
      }
    end
    phase_forms
  end
end

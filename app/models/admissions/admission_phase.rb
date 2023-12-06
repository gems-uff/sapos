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

  belongs_to :member_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "member_form_id"
  belongs_to :shared_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "shared_form_id"
  belongs_to :consolidation_form, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "consolidation_form_id"

  validates :name, presence: true

  def to_label
    "#{self.name}"
  end

  def has_committee_for_candidate(candidate)
    committees = self.admission_committees
    committees.any? do |committee|
      candidate.satisfies_conditions(committee.form_conditions)
    end || committees.empty?
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
        name: "Compartilhado",
        object: object,
        field: :results,
        form_template: self.shared_form,
        hidden: [:id, :admission_phase_id, :mode],
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
          name: "Individual",
          object: object,
          field: :evaluations,
          form_template: self.member_form,
          hidden: [:id, :admission_phase_id, :user_id],
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
        name: "Consolidação",
        object: object,
        field: :results,
        form_template: self.consolidation_form,
        hidden: [:id, :admission_phase_id, :mode],
      }
    end
    phase_forms
  end
end

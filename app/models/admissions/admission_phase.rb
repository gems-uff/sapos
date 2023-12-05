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
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseResult < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_phase, optional: false,
    class_name: "Admissions::AdmissionPhase"
  belongs_to :admission_application, optional: false,
    class_name: "Admissions::AdmissionApplication"
  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"

  accepts_nested_attributes_for :filled_form, allow_destroy: true

  validates :admission_phase_id, uniqueness: { scope: [
    :admission_application_id, :mode ] }

  SHARED = record_i18n_attr("modes.shared")
  CONSOLIDATION = record_i18n_attr("modes.consolidation")

  RESULT_MODES = [
    SHARED, CONSOLIDATION
  ]

  validates :mode, presence: true, inclusion: { in: RESULT_MODES }

  after_initialize :initialize_filled_form

  def initialize_filled_form
    if self.mode == SHARED
      template = self.admission_phase.shared_form
    else
      template = self.admission_phase.consolidation_form
    end
    self.filled_form ||= Admissions::FilledForm.new(
      is_filled: false,
      form_template: template
    )
  end

  def to_label
    "#{self.admission_application.to_label} - #{self.admission_phase.to_label}"
  end
end

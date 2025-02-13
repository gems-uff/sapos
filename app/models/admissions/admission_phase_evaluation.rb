# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseEvaluation < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_phase, optional: false,
    class_name: "Admissions::AdmissionPhase"
  belongs_to :user, optional: false,
    class_name: "User"
  belongs_to :admission_application, optional: false,
    class_name: "Admissions::AdmissionApplication"
  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"

  accepts_nested_attributes_for :filled_form, allow_destroy: true

  validates :admission_phase_id, uniqueness: { scope: [
    :admission_application_id, :user_id ] }

  after_initialize :initialize_filled_form

  def initialize_filled_form
    return if self.admission_phase.blank?
    self.filled_form ||= Admissions::FilledForm.new(
      is_filled: false,
      form_template: self.admission_phase.member_form
    )
  end

  def to_label
    "#{self.admission_phase.to_label} / #{self.admission_application.to_label} / #{self.user.to_label}"
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Dismissal for a Enrollment
class Dismissal < ApplicationRecord
  include ::MonthYearConcern

  has_paper_trail

  belongs_to :dismissal_reason, optional: false
  belongs_to :enrollment, optional: false

  validates :dismissal_reason, presence: true
  validates :enrollment, presence: true
  validates :date, presence: true
  validates_date :date,
    on_or_after: :enrollment_admission_date,
    on_or_after_message: :date_before_enrollment_admission_date

  validate :if_enrollment_has_not_scholarship
  validate :enrollment_keeps_accredited_advisor

  month_year_date :date

  def to_label
    date.to_fs
  end

  def enrollment_admission_date
    enrollment.admission_date unless enrollment.blank?
  end

  def if_enrollment_has_not_scholarship
    return if enrollment.blank?
    return if date.blank?
    any_active_scholarship = enrollment.scholarship_durations.any? do |sd|
      sd.active?(date: date)
    end
    if any_active_scholarship
      errors.add(:enrollment, :enrollment_has_scholarship)
    end
  end

  # Na matrícula desligada, a regra de credenciamento vale no mês do
  # desligamento (Enrollment#enrollment_has_authorized_advisor). Gravado por
  # esta tela, o desligamento não passa pela validação da matrícula, que
  # ficaria inválida e só acusaria na próxima edição, longe de quem a causou.
  def enrollment_keeps_accredited_advisor
    return unless CustomVariable.enable_advisor_accreditation_validation
    return if enrollment.blank? || enrollment.level.blank? || date.blank?
    advisements = enrollment.advisements.reject(&:marked_for_destruction?)
    return if advisements.empty?
    period = enrollment.advisor_accreditation_period(date)
    return if enrollment.any_accredited_advisor?(advisements, period)
    errors.add(:enrollment, :no_advisor_with_level)
  end
end

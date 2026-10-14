# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Indicates that a Professor is accredited to advise at a Level during a period.
# Each row is one accreditation period: start_date is the accreditation date and
# end_date the last day the accreditation was valid (nil while still open). A
# professor can be accredited, de-accredited and re-accredited over time, so the
# history is kept as several rows per (professor, level) instead of a single one.
class AdvisementAuthorization < ApplicationRecord
  include PeriodConcern

  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :level, optional: false

  validates :professor, presence: true
  validates :level, presence: true
  validates :start_date, presence: true
  validates_date :end_date, on_or_after: :start_date, allow_blank: true

  # Um professor não pode ter dois credenciamentos que se cruzam no mesmo
  # nível: o histórico é uma sequência de períodos disjuntos. O término é
  # inclusivo, coerente com #active_on? e #on_date: um período que termina em
  # 31/12 e outro que começa em 01/01 são disjuntos, mas dois que compartilham
  # um dia valeriam os dois nele.
  period scope: [:professor_id, :level_id],
    parent: :level, siblings: :advisement_authorizations,
    end_inclusive: true

  # Rows whose accreditation period contains +date+ — the SQL analog of
  # #active_on?. Inclusive on both ends: the end_date day still counts as active.
  # start_date/end_date are wrapped in DATE() so a stored time-of-day never shifts
  # the comparison (the same reason Affiliation#on_date does it), matching the
  # to_date coercion #active_on? uses in Ruby.
  scope :on_date, ->(date) {
    where(
      "DATE(advisement_authorizations.start_date) <= :date AND " \
      "(advisement_authorizations.end_date IS NULL OR " \
      "DATE(advisement_authorizations.end_date) >= :date)",
      date: date
    )
  }

  def to_label
    "#{level.name}"
  end

  # True when the accreditation period contains +date+. An open period
  # (end_date nil) has not been closed, so it covers any date from start_date on.
  # The end_date day itself still counts as active (inclusive), matching the
  # on_date scope.
  def active_on?(date)
    return false if start_date.blank?
    start_date.to_date <= date && (end_date.nil? || date <= end_date.to_date)
  end
end

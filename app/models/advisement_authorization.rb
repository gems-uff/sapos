# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Indicates that a Professor is accredited to advise at a Level during a period.
# Each row is one accreditation period: start_date is the accreditation date and
# end_date the de-accreditation date (nil while active). A professor can be
# accredited, de-accredited and re-accredited over time, so the history is kept
# as several rows per (professor, level) instead of a single one.
class AdvisementAuthorization < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :level, optional: false

  validates :professor, presence: true
  validates :level, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :single_active_authorization

  scope :active, -> { where(end_date: nil) }

  def to_label
    "#{level.name}"
  end

  # True when the accreditation period contains +date+. An open period
  # (end_date nil) has not been closed, so it covers any date from start_date on.
  def active_on?(date)
    return false if start_date.blank?
    start_date.to_date <= date && (end_date.nil? || date <= end_date.to_date)
  end

  private
    def end_date_after_start_date
      return if end_date.blank? || start_date.blank?
      if end_date < start_date
        errors.add(
          :end_date,
          "A data de descredenciamento não pode ser anterior à " \
          "data de credenciamento"
        )
      end
    end

    # Um professor não pode ter dois credenciamentos abertos no mesmo nível:
    # para recredenciar, o período anterior precisa ter sido encerrado.
    def single_active_authorization
      return unless end_date.nil?
      exists = AdvisementAuthorization
        .where(professor_id: professor_id, level_id: level_id, end_date: nil)
        .where.not(id: id).exists?
      if exists
        errors.add(
          :base,
          "Já existe um credenciamento ativo para este orientador neste nível"
        )
      end
    end
end

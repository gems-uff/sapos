# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Grant < ApplicationRecord
  has_paper_trail
  belongs_to :professor, optional: false

  PUBLIC = I18n.translate(
    "activerecord.attributes.grant.kinds.public"
  )
  PRIVATE = I18n.translate(
    "activerecord.attributes.grant.kinds.private"
  )
  KINDS = [PUBLIC, PRIVATE]

  validates :title, presence: true
  validates :start_year, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :funder, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :professor, presence: true
  validate :that_professor_cannot_edit_other_grants, if: -> { cannot?(:edit_professor, self) }
  validate :that_end_year_is_greater_than_start_year


  def that_professor_cannot_edit_other_grants
    current_professor = current_user&.professor
    return if current_professor.nil?
    if self.changes[:professor_id].present? && self.changes[:professor_id] != [nil, current_professor.id]
      self.errors.add(:professor, :cannot_edit_other_grants)
    end
  end

  def that_end_year_is_greater_than_start_year
    return if self.end_year.nil?
    if self.end_year < self.start_year
      self.errors.add(:end_year, :start_greater_than_end)
    end
  end

  def to_label
    "[#{self.start_year}] #{self.title}"
  end

  private
    delegate :can?, :cannot?, to: :ability

    def ability
      @ability ||= Ability.new(current_user)
    end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Paper < ApplicationRecord
  has_paper_trail

  attr_accessor :reason_group, :reason_group_end, :header

  belongs_to :owner, optional: false, class_name: "Professor"
  has_many :paper_professors, dependent: :destroy
  has_many :paper_students, dependent: :destroy
  has_many :professors, through: :paper_professors
  has_many :students, through: :paper_students

  JOURNAL = I18n.translate(
    "activerecord.attributes.paper.kinds.journal"
  )
  CONFERENCE = I18n.translate(
    "activerecord.attributes.paper.kinds.conference"
  )
  KINDS = [JOURNAL, CONFERENCE]

  ORDERS = [1, 2, 3, 4, 5, 6, 7, 8]

  validates :reference, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :doi_issn_event, presence: true
  validates :reason_justify, presence: true
  validates :order, presence: true, inclusion: { in: ORDERS }, uniqueness: {
    scope: [:period, :owner_id], message: :order_uniqueness
  }

  validate :that_professor_cannot_edit_other_papers, if: -> { cannot?(:edit_professor, self) }

  def that_professor_cannot_edit_other_papers
    current_professor = current_user&.professor
    return if current_professor.nil?
    if self.changes[:owner_id].present? && self.changes[:owner_id] != [nil, current_professor.id]
      self.errors.add(:owner, :cannot_edit_other_papers)
    end
  end

  def to_label
    "[#{self.owner.to_label}] #{self.reference}"
  end

  private
    delegate :can?, :cannot?, to: :ability

    def ability
      @ability ||= Ability.new(current_user)
    end
end

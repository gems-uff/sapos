# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ProfessorResearchLine < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :research_line, optional: false

  validate :verify_area

  validates :professor, presence: true
  validates :research_line, presence: true
  validates :professor,
    uniqueness: { scope: :research_line_id, message: :unique_pair }

  def to_label
    "#{self.professor.name} - #{self.research_line.name}"
  end

  def verify_area
    puts "AAAAAAAAAAAAAAAAAAAAAAA"
    unless professor.research_areas.include?(research_line.research_area)
      errors.add(:professor, :professor_area)
    end
  end
end

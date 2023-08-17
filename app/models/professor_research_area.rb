# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents ResearchArea of a Professor
class ProfessorResearchArea < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :research_area, optional: false

  validates :professor, presence: true
  validates :research_area, presence: true
  # A professor can't have the same research_area more than once
  validates :professor,
    uniqueness: { scope: :research_area_id, message: :unique_pair }

  def to_label
    "#{self.professor.name} - #{self.research_area.name}"
  end
end

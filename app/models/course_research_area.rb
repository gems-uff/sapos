# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents the ResearchArea of a Course
class CourseResearchArea < ApplicationRecord
  has_paper_trail

  belongs_to :course, optional: false
  belongs_to :research_area, optional: false

  validates :course, presence: true
  validates :research_area, presence: true
  validates :course,
    uniqueness: { scope: :research_area_id, message: :unique_pair }

  def to_label
    "#{self.course.name} - #{self.research_area.name}"
  end
end

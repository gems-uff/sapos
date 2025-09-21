# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseResearchLine < ApplicationRecord
  has_paper_trail

  belongs_to :course, optional: false
  belongs_to :research_line, optional: false

  validate :verify_area

  validates :course, presence: true
  validates :research_line, presence: true
  validates :course,
    uniqueness: { scope: :research_line_id, message: :unique_pair }

  def to_label
    "#{self.research_line.name} - #{self.research_line.research_area.name}"
  end

  def verify_area
    unless course.blank? || research_line.blank? || course.research_areas.include?(research_line.research_area)
      errors.add(:research_line, :course_area)
    end
  end
end

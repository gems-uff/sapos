# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseClassProfessor < ApplicationRecord
  has_paper_trail

  belongs_to :course_class, optional: false
  belongs_to :professor, optional: false

  validates :professor_id, uniqueness: {
    scope: :course_class_id,
    message: :taken
  }

  def to_label
    "#{self.professor.to_label} - #{self.course_class.to_label}"
  end
end
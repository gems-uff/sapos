# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a type of Course
class CourseType < ApplicationRecord
  has_paper_trail

  has_many :courses, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true

  def to_label
    "#{self.name}"
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents the Major of a Student
class StudentMajor < ApplicationRecord
  has_paper_trail

  belongs_to :student, optional: false
  belongs_to :major, optional: false

  validates :student, presence: true
  validates :major, presence: true

  validates :student, uniqueness: { scope: :major_id, message: :unique_pair }

  def to_label
    "#{self.student.name} - #{self.major.name}"
  end
end

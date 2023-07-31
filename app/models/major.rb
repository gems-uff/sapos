# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Major
class Major < ApplicationRecord
  has_paper_trail

  belongs_to :level, optional: false
  belongs_to :institution, optional: false

  has_many :student_majors, dependent: :destroy
  has_many :students, through: :student_majors

  validates :name, presence: true
  validates :institution, presence: true
  validates :level, presence: true

  def to_label
    "#{name} - #{institution.name} - (#{level.name})"
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ResearchLine < ApplicationRecord
  has_paper_trail

  belongs_to :research_area, optional: false

  has_many :course_research_lines, dependent: :destroy
  has_many :courses, through: :course_research_lines
  has_many :enrollments, dependent: :nullify
  has_many :professor_research_lines, dependent: :destroy
  has_many :professors, through: :professor_research_lines

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def to_label
    "#{code} - #{name}"
  end
end

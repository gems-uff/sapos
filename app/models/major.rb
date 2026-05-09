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

  def self.search_name(
    major: nil, institution: nil, level: nil,
    substring: false, ignore_association: false
  )
    major = "%#{major}%" if major.present? && substring
    institution = "%#{institution}%" if institution.present? && substring
    level = "%#{level}%" if level.present? && substring
    majors = Major
    majors = majors.joins(:institution).where(
      "`institutions`.`name` LIKE :institution
      OR `institutions`.`code` LIKE :institution
      ", {institution: institution}
    ) if institution.present?
    majors = majors.joins(:level).where(
      "`levels`.`name` LIKE :level
      ", {level: level}
    ) if level.present?
    majors = majors.where(
      "`majors`.`name` LIKE :major
      ", {major: major}
    )
    if majors.empty? && ignore_association
      majors = Major.where(
        "`majors`.`name` LIKE :major
        ", {major: major}
      )
    end
    majors
  end
end

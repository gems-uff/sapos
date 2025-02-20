# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents an institution
class Institution < ApplicationRecord
  has_paper_trail

  has_many :majors, dependent: :restrict_with_exception
  has_many :affiliations
  has_many :professors, through: :affiliations


  validates :name, presence: true, uniqueness: true

  def to_label
    "#{self.name}"
  end

  def self.search_name(institution: nil, substring: false)
    institution = "%#{institution}%" if institution.present? && substring
    Institution.where(
      "name COLLATE :db_collation
        LIKE :institution COLLATE :value_collation
       OR code COLLATE :db_collation
        LIKE :institution COLLATE :value_collation
      ", Collation.collations.merge(institution:)
    )
  end
end

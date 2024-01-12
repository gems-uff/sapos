# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Country State
class State < ApplicationRecord
  has_paper_trail

  belongs_to :country, optional: false

  has_many :cities, dependent: :restrict_with_exception
  has_many :student_birth_states,
    class_name: "Student",
    foreign_key: "birth_state_id",
    dependent: :restrict_with_exception

  validates :country, presence: true
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def to_label
    "#{self.name}"
  end

  def self.search_name(state: nil, country: nil, substring: false)
    state = "%#{state}%" if state.present? && substring
    country = "%#{country}%" if country.present? && substring
    states = State
    states = states.joins(:country).where(
      "`countries`.`name` COLLATE :db_collation
        LIKE :country COLLATE :value_collation
      ", Collation.collations.merge(country:)
    ) if country.present?
    states.where(
      "`states`.`name` COLLATE :db_collation
        LIKE :state COLLATE :value_collation
        OR `states`.`code` COLLATE :db_collation
        LIKE :state COLLATE :value_collation
      ", Collation.collations.merge(state:)
    )
  end

  def full_name
    "#{self.name}, #{self.country.name}"
  end
end

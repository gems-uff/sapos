# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a city
class City < ApplicationRecord
  has_paper_trail

  belongs_to :state, optional: false

  has_many :students, dependent: :restrict_with_exception
  has_many :student_birth_cities,
    class_name: "Student", foreign_key: "birth_city_id",
    dependent: :restrict_with_exception
  has_many :professors, dependent: :restrict_with_exception


  validates :state, presence: true
  validates :name, presence: true

  def to_label
    "#{self.name}"
  end

  def self.search_name(city: nil, state: nil, country: nil, substring: false)
    city = "%#{city}%" if city.present? && substring
    state = "%#{state}%" if state.present? && substring
    country = "%#{country}%" if country.present? && substring
    cities = City
    cities = cities.joins(:state) if country.present? || state.present?
    cities = cities.joins(state: :country).where(
      "`countries`.`name` COLLATE :db_collation
        LIKE :country COLLATE :value_collation
      ", Collation.collations.merge(country:)
    ) if country.present?
    cities = cities.where(
      "`states`.`name` COLLATE :db_collation
        LIKE :state COLLATE :value_collation
        OR `states`.`code` COLLATE :db_collation
        LIKE :state COLLATE :value_collation
      ", Collation.collations.merge(state:)
    ) if state.present?
    cities.where(
      "`cities`.`name` COLLATE :db_collation
        LIKE :city COLLATE :value_collation
      ", Collation.collations.merge(city:)
    )
  end

  def full_name
    "#{self.name}, #{self.state.name}, #{self.state.country.name}"
  end
end

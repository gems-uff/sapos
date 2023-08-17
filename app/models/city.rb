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
end

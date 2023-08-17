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
end

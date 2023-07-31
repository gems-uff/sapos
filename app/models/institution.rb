# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents an institution
class Institution < ApplicationRecord
  has_paper_trail

  has_many :majors, dependent: :restrict_with_exception
  has_many :professors, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true

  def to_label
    "#{self.name}"
  end
end

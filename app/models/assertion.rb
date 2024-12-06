# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Assertion < ApplicationRecord
  has_paper_trail

  attr_accessor :args
  belongs_to :query, inverse_of: :assertions, optional: false

  validates :name, presence: true
  validates :assertion_template, presence: true, on: :update

  def to_label
    "#{self.name}"
  end
end
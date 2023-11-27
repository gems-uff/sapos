# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormCondition < ActiveRecord::Base
  has_paper_trail

  belongs_to :model, polymorphic: true

  validates :field, presence: true

  def to_label
    "#{self.field} #{self.condition} #{self.value}"
  end
end

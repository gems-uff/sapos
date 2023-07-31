# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Indicates that a Professor can advise at a Level
class AdvisementAuthorization < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :level, optional: false

  validates :professor, presence: true
  validates :level, presence: true

  def to_label
    "#{level.name}"
  end
end

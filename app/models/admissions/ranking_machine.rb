# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingMachine < ActiveRecord::Base
  has_paper_trail

  has_many :ranking_processes, dependent: :destroy,
    class_name: "Admissions::RankingProcess"
  has_many :form_conditions, as: :model, dependent: :destroy,
    class_name: "Admissions::FormCondition"

  validates :name, presence: true

  def to_label
    "#{self.name}"
  end
end

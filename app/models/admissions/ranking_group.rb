# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingGroup < ActiveRecord::Base
  has_paper_trail

  belongs_to :ranking_config, optional: false,
    class_name: "Admissions::RankingConfig"

  validates :name, presence: true

  def to_label
    "#{self.name} #{self.vacancies}"
  end

  def total_vacancies
    return Float::INFINITY if self.vacancies.nil?
    self.vacancies
  end
end

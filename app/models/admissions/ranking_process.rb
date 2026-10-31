# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingProcess < ActiveRecord::Base
  has_paper_trail

  belongs_to :ranking_config, optional: false,
    class_name: "Admissions::RankingConfig"
  belongs_to :ranking_machine, optional: false,
    class_name: "Admissions::RankingMachine"

  validates :step, presence: true

  def to_label
    "#{self.ranking_machine.name} #{self.vacancies}-#{self.group}"
  end

  def calculate_remaining(groups, process_vacancies)
    existing = process_vacancies[self.id]
    existing = Float::INFINITY if existing.nil?
    group_vacancies = nil
    group_vacancies = groups[self.group] if self.group.present?
    group_vacancies = Float::INFINITY if group_vacancies.nil?
    this_vacancies = self.vacancies
    this_vacancies = Float::INFINITY if this_vacancies.nil?
    [existing, group_vacancies, this_vacancies].min()
  end

  def decrease_vacancies!(groups, process_vacancies)
    process_vacancies[self.id] -= 1
    self.decrease_group!(groups)
  end

  def decrease_group!(groups)
    return if self.group.blank? || groups[self.group].nil?
    groups[self.group] -= 1
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingProcess < ActiveRecord::Base
  has_paper_trail

  belongs_to :ranking_config, optional: false,
    class_name: "Admissions::RankingConfig"
  belongs_to :ranking_machine, optional: false,
    class_name: "Admissions::RankingMachine"

  def to_label
    "#{self.ranking_machine.name} #{self.vacancies}-#{self.group}"
  end
end

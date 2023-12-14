# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingColumn < ActiveRecord::Base
  has_paper_trail

  ASC = record_i18n_attr("orders.asc")
  DESC = record_i18n_attr("orders.desc")

  ORDERS = [DESC, ASC]

  belongs_to :ranking_config, optional: false,
    class_name: "Admissions::RankingConfig"

  validates :name, presence: true
  validates :order, presence: true, inclusion: { in: ORDERS }

  def to_label
    "#{self.name} #{self.order}"
  end
end

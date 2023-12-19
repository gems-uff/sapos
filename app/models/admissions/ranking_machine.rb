# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingMachine < ActiveRecord::Base
  has_paper_trail

  has_many :ranking_processes, dependent: :destroy,
    class_name: "Admissions::RankingProcess"

  belongs_to :form_condition, optional:true,
    class_name: "Admissions::FormCondition"

  validates :name, presence: true

  accepts_nested_attributes_for :form_condition,
    reject_if: :all_blank,
    allow_destroy: true

  def to_label
    "#{self.name}"
  end

  def initialize_dup(other)
    super
    self.form_condition = other.form_condition.dup
  end
end

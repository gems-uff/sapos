# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingColumn < ActiveRecord::Base
  has_paper_trail

  ASC = record_i18n_attr("orders.asc")
  DESC = record_i18n_attr("orders.desc")

  ORDERS = [DESC, ASC]

  belongs_to :ranking_config, optional: true,
    class_name: "Admissions::RankingConfig"
  belongs_to :admission_report_config, optional: true,
    class_name: "Admissions::AdmissionReportConfig"

  validates :name, presence: true
  validates :order, presence: true, inclusion: { in: ORDERS }
  validates :ranking_config, presence: true,
    unless: ->(rc) { rc.admission_report_config_id.present? }
  validates :admission_report_config, presence: true,
    unless: ->(rc) { rc.ranking_config_id.present? }

  after_initialize :initialize_conversion

  def to_label
    "#{self.name} #{self.order}"
  end

  def initialize_conversion
    @conversion = nil
  end

  def compare(first, second)
    comparison = first <=> second
    comparison *= -1 if self.order == DESC
    comparison
  end

  def convert(field)
    return nil if field.nil?
    if @conversion.nil?
      @conversion = field.get_type
    end
    Admissions::FilledFormField.convert_value(field.simple_value, @conversion)
  end
end

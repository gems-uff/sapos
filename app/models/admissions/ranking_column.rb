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

  validate :that_field_name_exists
  validate :that_it_either_has_ranking_config_or_admission_report_config

  after_initialize :initialize_conversion

  def that_it_either_has_ranking_config_or_admission_report_config
    return if self.ranking_config.present? == self.admission_report_config.blank?
    self.errors.add(:base, :at_least_one_relationship)
  end

  def that_field_name_exists
    return if self.name.blank?
    return if Admissions::FormField.field_name_exists?(self.name)
    self.errors.add(:base, :field_not_found, field: self.name)
  end

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

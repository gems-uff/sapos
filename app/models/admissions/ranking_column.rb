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
    case @conversion
    when "string"
      self.convert_string(field.simple_value)
    when "number"
      self.convert_number(field.simple_value)
    when "date"
      self.convert_date(field.simple_value)
    else
      case field.form_field.field_type
      when Admissions::FormField::NUMBER
        @conversion = "number"
      when Admissions::FormField::DATE
        @conversion = "date"
      when Admissions::FormField::STUDENT_FIELD
        case config["field"]
        when "birthdate", "identity_expedition_date"
          @conversion = "date"
        else
          @conversion = "string"
        end
      else
        @conversion = "string"
      end
      self.convert(field)
    end
  end

  def convert_string(field)
    field.to_s
  rescue
    nil
  end

  def convert_number(field)
    field.to_f
  rescue
    nil
  end

  def convert_date(field)
    Date.strptime(self.value, "%d/%m/%Y")
  rescue
    nil
  end
end

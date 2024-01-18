# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportColumn < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_report_group, optional: false,
    class_name: "Admissions::AdmissionReportGroup"

  validates :name, presence: true
  validate :that_field_name_exists

  def to_label
    "#{self.name}"
  end

  def that_field_name_exists
    return if self.name.blank?
    return if Admissions::FormField.field_name_exists?(
      self.name, in_main: true, in_letter: true
    )
    self.errors.add(:base, :field_not_found, field: self.name)
  end
end

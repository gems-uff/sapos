# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportColumn < ActiveRecord::Base
  has_paper_trail

  belongs_to :group, optional: false,
    class_name: "Admissions::AdmissionReportGroup"

  validates :name, presence: true

  def to_label
    "#{self.name}"
  end
end

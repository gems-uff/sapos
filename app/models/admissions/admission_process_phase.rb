# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcessPhase < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_process, optional: false,
    class_name: "Admissions::AdmissionProcess"
  belongs_to :admission_phase, optional: false,
    class_name: "Admissions::AdmissionPhase"

  def to_label
    "#{self.admission_process.to_label} - #{self.admission_phase.to_label}"
  end
end

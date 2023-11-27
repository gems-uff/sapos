# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseCommittee < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_phase, optional: false,
    class_name: "Admissions::AdmissionPhase"
  belongs_to :admission_committee, optional: false,
    class_name: "Admissions::AdmissionCommittee"

  def to_label
    "#{self.admission_phase.to_label} - #{self.admission_committee.to_label}"
  end
end

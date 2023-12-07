# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionPhaseCommittee < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_phase, optional: false,
    class_name: "Admissions::AdmissionPhase"
  belongs_to :admission_committee, optional: false,
    class_name: "Admissions::AdmissionCommittee"

  after_commit :update_pendencies

  def update_pendencies
    self.admission_phase.update_pendencies
    old = previous_changes.try(:admission_phase).try(:[], 0)
    if old.present?
      old.update_pendencies
    end
  end

  def to_label
    "#{self.admission_phase.to_label} - #{self.admission_committee.to_label}"
  end
end

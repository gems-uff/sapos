# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionCommitteeMember < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_committee, optional: false,
    class_name: "Admissions::AdmissionCommittee"
  belongs_to :user, optional: false,
    class_name: "User"

  def to_label
    "#{self.admission_committee.to_label} - #{self.user.to_label}"
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionCommittee < ActiveRecord::Base
  has_paper_trail

  has_many :members, dependent: :destroy,
    class_name: "Admissions::AdmissionCommitteeMember"
  has_many :users, through: :members,
    class_name: "User"
  has_many :form_conditions, as: :model, dependent: :destroy,
    class_name: "Admissions::FormCondition"
  has_many :admission_phase_committees, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseCommittee"
  has_many :admission_phases, through: :admission_phase_committees,
    class_name: "Admissions::AdmissionPhase"

  validates :name, presence: true

  def to_label
    self.name
  end
end

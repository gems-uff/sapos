# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionCommittee < ActiveRecord::Base
  has_paper_trail

  has_many :members, dependent: :destroy,
    class_name: "Admissions::AdmissionCommitteeMember"
  has_many :users, through: :members,
    class_name: "User"
  has_many :admission_phase_committees, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseCommittee"
  has_many :admission_phases, through: :admission_phase_committees,
    class_name: "Admissions::AdmissionPhase"

  belongs_to :form_condition, optional:true,
    class_name: "Admissions::FormCondition"

  validates :name, presence: true

  accepts_nested_attributes_for :form_condition,
    reject_if: :all_blank,
    allow_destroy: true

  after_commit :update_pendencies

  def update_pendencies
    self.admission_phase_committees.each do |pc|
      pc.update_pendencies
    end
  end

  def to_label
    self.name
  end

  def initialize_dup(other)
    super
    self.members = other.members.map(&:dup)
    self.form_condition = other.form_condition.dup
  end
end

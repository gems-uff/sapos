# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a major Level
class Level < ApplicationRecord
  has_paper_trail

  has_many :advisement_authorizations, dependent: :destroy
  has_many :enrollments, dependent: :restrict_with_exception
  has_many :majors, dependent: :restrict_with_exception
  has_many :phase_durations, dependent: :restrict_with_exception
  has_many :scholarships, dependent: :restrict_with_exception
  has_many :application_processes, dependent: :nullify,
    class_name: "Admissions::AdmissionProcess"

  validates :name, presence: true, uniqueness: true
  validates :default_duration, presence: true

  def to_label
    "#{self.name}"
  end

  def full_name
    return self.name if self.course_name.blank?
    self.course_name
  end
end

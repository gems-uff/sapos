# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents the participation of a Professor in the thesis defense committee of an Enrollment
class ThesisDefenseCommitteeParticipation < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :enrollment, optional: false

  validates :professor, presence: true
  validates :enrollment, presence: true
  validates :professor, uniqueness: {
    scope: :enrollment_id,
    message: :thesis_defense_committee_participation_professor_uniqueness
  }

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"
  end
end

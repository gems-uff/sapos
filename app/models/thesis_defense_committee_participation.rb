# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ThesisDefenseCommitteeParticipation < ApplicationRecord
  belongs_to :professor
  belongs_to :enrollment

  has_paper_trail

  validates :professor, :presence => true
  validates :enrollment, :presence => true

  validates :professor_id, :uniqueness => {:scope => :enrollment_id, :message => :thesis_defense_committee_participation_professor_uniqueness} 

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"
  end
end

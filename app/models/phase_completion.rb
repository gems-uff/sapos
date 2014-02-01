#encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhaseCompletion < ActiveRecord::Base
  attr_accessible :completion_date, :due_date, :enrollment_id, :phase_id

  belongs_to :enrollment
  belongs_to :phase

  validates :enrollment_id, :presence => true
  validates :phase_id, :presence => true
  validates :phase_id, :uniqueness => {:scope => :enrollment_id}
end

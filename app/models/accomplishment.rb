# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :phase_id}
  validates :phase, :presence => true

  def to_label
    "#{phase.name}"    
  end
  
end

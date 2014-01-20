# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :phase_id, :message => :accomplishment_enrollment_uniqueness}
  validates :phase, :presence => true

  after_save :set_completion_date

  def to_label
    "#{phase.name}"    
  end

  def set_completion_date
  	phase_completion = PhaseCompletion.where(:enrollment_id => enrollment_id, :phase_id => phase_id).first
  	if phase_completion
	  phase_completion.completion_date = conclusion_date
	  phase_completion.save
	end
  end
  
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ProfessorResearchArea < ActiveRecord::Base
  attr_accessible :professor, :research_area
  
  belongs_to :professor
  belongs_to :research_area

  has_paper_trail

  validates :professor, :presence => true
  validates :research_area, :presence => true

  validates :professor_id, :uniqueness => {:scope => :research_area_id, :message => :unique_pair} #A professor can't have the same research_area more than once

  def to_label
  	"#{self.professor.name} - #{self.research_area.name}"
  end
end

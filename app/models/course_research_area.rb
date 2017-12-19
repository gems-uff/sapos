# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseResearchArea < ApplicationRecord
  # attr_accessible :course, :research_area, :course_id, :research_area_id
  
  belongs_to :course
  belongs_to :research_area

  has_paper_trail

  validates :course, :presence => true
  validates :research_area, :presence => true

  validates :course_id, :uniqueness => {:scope => :research_area_id, :message => :unique_pair}

  def to_label
  	"#{self.course.name} - #{self.research_area.name}"
  end
end

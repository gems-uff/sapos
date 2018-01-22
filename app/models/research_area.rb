# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ResearchArea < ApplicationRecord

  has_many :course_research_areas, :dependent => :destroy
  has_many :courses, :through => :course_research_areas
  
  has_many :enrollments, :dependent => :restrict_with_exception
  has_many :professor_research_areas, :dependent => :destroy
  has_many :professors, :through => :professor_research_areas
  
  has_paper_trail

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true


  def to_label
    "#{code} - #{name}"
  end
end

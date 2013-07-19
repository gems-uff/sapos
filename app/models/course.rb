# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Course < ActiveRecord::Base
  attr_accessible :name
  belongs_to :research_area
  belongs_to :course_type

  validates :course_type, :presence => true
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :credits, :presence => true
end

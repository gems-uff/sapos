# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentMajor < ActiveRecord::Base
  attr_accessible :student, :major
  
  belongs_to :student
  belongs_to :major

  validates :student, :presence => true
  validates :major, :presence => true

  validates :student_id, :uniqueness => {:scope => :major_id, :message => :unique_pair} 
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentMajor < ApplicationRecord
  has_paper_trail
  
  belongs_to :student
  belongs_to :major

  validates :student, :presence => true
  validates :major, :presence => true

  validates :student_id, :uniqueness => {:scope => :major_id, :message => :unique_pair} 

  def to_label
    "#{self.student.name} - #{self.major.name}"
  end
end

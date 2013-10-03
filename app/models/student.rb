# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Student < ActiveRecord::Base
  attr_accessible :name
  has_many :majors, :through => :student_majors
  has_many :student_majors, :dependent => :destroy
    
  belongs_to :birthplace, :foreign_key => "state_id", :class_name => "State"
  belongs_to :state
  
  belongs_to :country
  belongs_to :city
  
  #delete cascade for enrollment -- when a student is deleted, so are his enrollments
  has_many :enrollments, :dependent => :destroy  
   
  validates :name, :presence => true
  validates :cpf, :presence => true, :uniqueness => true

  def enrollments_number
    self.enrollments.collect { |enrollment| 
      enrollment.enrollment_number 
    }.join(', ')
  end
  
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Student < ActiveRecord::Base

  mount_uploader :photo, ProfileUploader

  has_many :majors, :through => :student_majors

  has_many :student_majors, :dependent => :destroy
  #delete cascade for enrollment -- when a student is deleted, so are his enrollments
  has_many :enrollments, :dependent => :restrict_with_exception
    
  belongs_to :city
  belongs_to :birth_city, :class_name => 'City', :foreign_key => 'birth_city_id'
  belongs_to :birth_state, :class_name => 'State', :foreign_key => 'birth_state_id' 
  
  has_paper_trail  
   
  validates :name, :presence => true
  validates :cpf, :presence => true, :uniqueness => true

  before_save :set_birth_state_by_birth_city

  def enrollments_number
    self.enrollments.collect { |enrollment| 
      enrollment.enrollment_number 
    }.join(', ')
  end
  
  def to_label
    "#{self.name}"
  end

  def birthplace
    return nil if birth_city.nil? and birth_state.nil?
    return "#{birth_state.country.name}" if birth_city.nil? 
    "#{birth_city.state.country.name}"
  end

  protected

  def set_birth_state_by_birth_city
    self.birth_state_id = birth_city.state_id unless birth_city.nil?
  end
end

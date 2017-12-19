# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Student < ApplicationRecord

  mount_uploader :photo, ProfileUploader

  has_many :majors, :through => :student_majors

  has_many :student_majors, :dependent => :destroy
  #delete cascade for enrollment -- when a student is deleted, so are his enrollments
  has_many :enrollments, :dependent => :restrict_with_exception
    
  belongs_to :city
  belongs_to :birth_city, :class_name => 'City', :foreign_key => 'birth_city_id'
  belongs_to :birth_state, :class_name => 'State', :foreign_key => 'birth_state_id' 
  belongs_to :birth_country, :class_name => 'Country', :foreign_key => 'birth_country_id'

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

  def nationality
    if not birth_country.nil?
      return "#{birth_country.nationality}"
    elsif not birth_state.nil?
      return "#{birth_state.country.nationality}"
    elsif not birth_city.nil?
      return "#{birth_city.state.country.nationality}"
    end
    nil    
  end

  def identity_issuing_place_to_label
    return "#{I18n.t('pdf_content.enrollment.header.identity_issuing_state')}" unless State.where("name LIKE ?", self.identity_issuing_place).empty?
    return "#{I18n.t('pdf_content.enrollment.header.identity_issuing_country')}"
  end

  def mount_uploader_name
    :photo
  end

  protected

  def set_birth_state_by_birth_city
    self.birth_state_id = birth_city.state_id unless birth_city.nil?
  end
end

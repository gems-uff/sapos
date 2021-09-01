# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Student < ApplicationRecord

  mount_uploader :photo, ProfileUploader

  has_many :student_majors, :dependent => :destroy
  has_many :majors, :through => :student_majors

  #delete cascade for enrollment -- when a student is deleted, so are his enrollments
  has_many :enrollments, :dependent => :restrict_with_exception
    
  belongs_to :city
  belongs_to :birth_city, :class_name => 'City', :foreign_key => 'birth_city_id'
  belongs_to :birth_state, :class_name => 'State', :foreign_key => 'birth_state_id' 
  belongs_to :birth_country, :class_name => 'Country', :foreign_key => 'birth_country_id'
  belongs_to :user, optional: true

  has_paper_trail  
   
  validates :name, :presence => true
  validates :cpf, :presence => true, :uniqueness => true
  validate :changed_to_different_user

  before_save :set_birth_state_by_birth_city
  
  def has_user?
    return true unless self.user_id.nil?
    ! User.where(email: self.emails).empty?
  end

  def has_email?
    ! (self.email.nil? || self.email.empty?)
  end

  def emails
    return [] unless self.has_email?
    return self.email.split(/[\s,;]/).filter { |email| email != "" }
  end

  def first_email
    emails = self.emails
    return nil if emails.empty?
    return emails[0]
  end

  def can_have_new_user?
    return false unless has_email?
    return false if has_user?
    return true 
  end

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

  def changed_to_different_user
    if (user_id_changed?) && (!user_id.nil?) && (!user_id_was.nil?)	  
      errors.add(:user, :changed_to_different_user)
    end
  end

  protected

  def set_birth_state_by_birth_city
    self.birth_state_id = birth_city.state_id unless birth_city.nil?
  end
end

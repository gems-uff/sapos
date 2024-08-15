# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Student
class Student < ApplicationRecord
  has_paper_trail

  mount_uploader :photo, ProfileUploader

  belongs_to :city, optional: true
  belongs_to :birth_city,
    optional: true,
    class_name: "City",
    foreign_key: "birth_city_id"
  belongs_to :birth_state,
    optional: true,
    class_name: "State",
    foreign_key: "birth_state_id"
  belongs_to :birth_country,
    optional: true,
    class_name: "Country",
    foreign_key: "birth_country_id"
  belongs_to :user, optional: true

  has_many :student_majors, dependent: :destroy
  has_many :majors, through: :student_majors

  has_many :enrollments, dependent: :restrict_with_exception
  has_many :admission_applications, dependent: :nullify,
    class_name: "Admissions::AdmissionApplication"

  validates :name, presence: true
  validates :cpf, presence: true, uniqueness: true
  validate :changed_to_different_user

  accepts_nested_attributes_for :student_majors, allow_destroy: true

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
    self.email.split(/[\s,;]/).filter { |email| email != "" }
  end

  def first_email
    emails = self.emails
    return nil if emails.empty?
    emails[0]
  end

  def can_have_new_user?
    return false unless has_email?
    return false if has_user?
    true
  end

  def enrollments_number
    self.enrollments.collect { |enrollment|
      enrollment.enrollment_number
    }.join(", ")
  end

  def to_label
    "#{self.name}"
  end

  def birthplace
    return nil if birth_city.blank? && birth_state.blank?
    return "#{birth_state.country.name}" if birth_city.blank?
    "#{birth_city.state.country.name}"
  end

  def nationality
    if birth_country.present?
      return "#{birth_country.nationality}"
    elsif birth_state.present?
      return "#{birth_state.country.nationality}"
    elsif birth_city.present?
      return "#{birth_city.state.country.nationality}"
    end
    nil
  end

  def mount_uploader_name
    :photo
  end

  def changed_to_different_user
    if (user_id_changed?) && (!user_id.blank?) && (!user_id_was.blank?)
      errors.add(:user, :changed_to_different_user)
    end
  end

  protected
    def set_birth_state_by_birth_city
      self.birth_state_id = birth_city.state_id unless birth_city.blank?
    end
end

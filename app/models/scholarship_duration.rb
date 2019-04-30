# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ScholarshipDuration < ApplicationRecord
  belongs_to :scholarship
  belongs_to :enrollment
  has_many :scholarship_suspensions

  has_paper_trail

  validates :scholarship, :presence => true
  validates :enrollment_id, :presence => true, :uniqueness => {:message => I18n.t("activerecord.errors.models.scholarship_duration.enrollment_and_scholarship_uniqueness"), :if => :student_has_other_scholarship_duration}
  validates :enrollment, :presence => true


  #validates if scholarship isn't with another student
  validate :if_scholarship_is_not_with_another_student


#  #validates if a scholarship duration start date isn't before it's end date
  validates_date :start_date, :on_or_before => :end_date, :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.attributes.start_date_after_end_date")
#
#  #validates if a scholarship duration isn't invalid according to the selected scholarship
  validates_date :start_date, :on_or_after => :scholarship_start_date, :on_or_after_message => I18n.t("activerecord.errors.models.scholarship_duration.start_date_before_scholarship_start_date")
  validates_date :start_date, :on_or_before => :scholarship_end_date, :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.start_date_after_scholarship_end_date")
  validates_date :end_date, :on_or_after => :scholarship_start_date, :on_or_after_message => I18n.t("activerecord.errors.models.scholarship_duration.end_date_before_scholarship_start_date")
  validates_date :end_date, :on_or_before => :scholarship_end_date, :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.end_date_after_scholarship_end_date")
#
#  #validates if a cancel date of an scholarship duration is valid
  validates_date :cancel_date, :on_or_before => :end_date, :allow_nil => true
  validates_date :cancel_date, :on_or_after => :start_date, :allow_nil => true

  before_save :update_end_and_cancel_dates

  def init
    self.start_date = Date.today.beginning_of_month + 1.month if self.start_date.nil?
    self.update_end_date
  end

  def update_end_date
    dates = []
    unless self.enrollment.nil? or self.enrollment.level.nil?
      dates << (self.enrollment.admission_date + (self.enrollment.level.default_duration - 1).months).end_of_month
    end
    unless self.scholarship.nil?
      dates << self.scholarship.end_date unless self.scholarship.end_date.nil?
    end
    self.end_date = dates.min
  end

  def to_label
    label = ""

    if start_date
      label = I18n.localize(start_date, :format => :monthyear)
    end
    if end_date
      label += " - #{I18n.localize(end_date, :format => :monthyear)}"
    end
    label
  end

  #this validation is only called for checking uniqueness of scholarship durations
  #if start date of a new scholarship duration is earlier than an existing scholarship duration then 
  def student_has_other_scholarship_duration
    return false if enrollment.nil?
    return false if scholarship.nil?
    #Se a bolsa é mais antiga que a atual    scholarship.start_date < start_date
    # -> scholarship.cancel_date não é nulo -> scholarhsip.cancel < start_date
    # -> scholarship.cancel_date é nulo -> schoarslhip.end_date < start_date
    #Senão
    # -> cancel_date não é nulo -> schoarslhip.start_date > cancel_date
    # -> scholarship.cancel_date é nulo -> schoarslhip.start_date > end_date

    if self.id.nil?
      scholarships_with_student = ScholarshipDuration.where(enrollment_id: enrollment.id).all
    else
      scholarships_with_student = ScholarshipDuration.where(enrollment_id: enrollment.id).where.not(id: self.id).all
    end

    scholarships_with_student.each do |scholarship|
      if scholarship.start_date <= start_date # se a bolsa é antiga
        if scholarship.cancel_date.nil?
          return true if scholarship.end_date >= start_date
        else
          return true if scholarship.cancel_date >= start_date
        end
      else # se a bolsa é futura
        if cancel_date.nil?
          return true if scholarship.start_date <= end_date
        else
          return true if scholarship.start_date <= cancel_date
        end
      end
    end

    false
  end

  def warning_message
    if self.id.nil?
      scholarships_with_student = ScholarshipDuration.where(scholarship_id: scholarship.id).all
    else
      scholarships_with_student = ScholarshipDuration.where(scholarship_id: scholarship.id).where.not(id: self.id).all
    end

    message = nil
    scholarships_with_student.each do |scholarship|
      if scholarship.start_date <= start_date and scholarship.cancel_date.nil?
        message = I18n.t("activerecord.errors.models.scholarship_duration.unfinished_scholarship")
        break
      end
    end
    message
  end

  def if_scholarship_is_not_with_another_student
    return if scholarship.nil?
    if self.id.nil?
      scholarships_with_student = ScholarshipDuration.where(scholarship_id: scholarship.id).all
    else
      scholarships_with_student = ScholarshipDuration.where(scholarship_id: scholarship.id).where.not(id: self.id).all
    end

    scholarships_with_student.each do |scholarship|
      if scholarship.start_date <= start_date # se a bolsa é antiga
        if scholarship.cancel_date.nil?
          if scholarship.end_date >= start_date
            errors.add(:start_date, I18n.t("activerecord.errors.models.scholarship_duration.start_date_before_scholarship_end_date"))
            break
          end
        else
          if scholarship.cancel_date >= start_date
            errors.add(:start_date, I18n.t("activerecord.errors.models.scholarship_duration.start_date_before_scholarship_cancel_date"))
            break
          end
        end
      else # se a bolsa é futura
        if cancel_date.nil?
          if scholarship.start_date <= end_date
            errors.add(:end_date, I18n.t("activerecord.errors.models.scholarship_duration.scholarship_start_date_after_end_or_cancel_date"))
            break
          end
        else
          if scholarship.start_date <= cancel_date
            errors.add(:cancel_date, I18n.t("activerecord.errors.models.scholarship_duration.scholarship_start_date_after_end_or_cancel_date"))
            break
          end
        end
      end
    end
  end

  def scholarship_end_date
    finder_scholarship = Scholarship.find :last, :conditions => ["id = ?", scholarship]
    finder_scholarship.end_date unless scholarship.nil?
  end

  def scholarship_start_date
    finder_scholarship = Scholarship.find :last, :conditions => ["id = ?", scholarship]
    finder_scholarship.start_date unless scholarship.nil?
  end

  def last_date
    return self.cancel_date.end_of_month unless self.cancel_date.nil?
    self.end_date.end_of_month
  end

  def was_cancelled?
    return false if self.cancel_date.nil?
    self.end_date != self.cancel_date
  end

  def active?(options={})
    date = options[:date].nil? ? Date.today : options[:date].to_date
    return false if date < self.start_date
    return self.end_date.end_of_month >= date if self.cancel_date.nil?
    (self.cancel_date.end_of_month - 1.month) >= date
  end

  def update_end_and_cancel_dates
    self.end_date = self.end_date.end_of_month unless self.end_date.nil?
    self.cancel_date = self.cancel_date.end_of_month unless self.cancel_date.nil?
  end

end

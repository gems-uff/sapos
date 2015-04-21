# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Dismissal < ActiveRecord::Base
  belongs_to :dismissal_reason
  belongs_to :enrollment

  has_paper_trail

  validates :date, :presence => true
  validates :dismissal_reason, :presence => true
  validates :enrollment, :presence => true
  validates_date :date, :on_or_after => :enrollment_admission_date, :on_or_after_message => I18n.t("activerecord.errors.models.dismissal.date_before_enrollment_admission_date")
  
  validate :if_enrollment_has_not_scholarship

  def to_label
    #"#{date.day}-#{date.month}-#{date.year}"    
    "#{date}"    
  end

  def enrollment_admission_date
    enrollment.admission_date unless enrollment.nil?
  end

  def if_enrollment_has_not_scholarship
    return if enrollment.nil?
    return if date.nil?
    any_active_scholarship = enrollment.scholarship_durations.any? do |sd|
      sd.active?(:date => date)
    end
    if any_active_scholarship
      errors.add(:enrollment, I18n.translate("activerecord.errors.models.dismissal.enrollment_has_scholarship")) 
    end
  end
  
end

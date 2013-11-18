# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Dismissal < ActiveRecord::Base
  belongs_to :dismissal_reason
  belongs_to :enrollment

  has_paper_trail

  validates :date, :presence => true
  validates :dismissal_reason, :presence => true
  validates :enrollment, :presence => true
  validates_date :date, :on_or_after => :enrollment_admission_date, :on_or_after_message => I18n.t("activerecord.errors.models.dismissal.date_before_enrollment_admission_date")
  

  def to_label
    #"#{date.day}-#{date.month}-#{date.year}"    
    "#{date}"    
  end

  def enrollment_admission_date
    enrollment.admission_date unless enrollment.nil?
  end
  
end

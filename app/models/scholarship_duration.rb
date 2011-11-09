class ScholarshipDuration < ActiveRecord::Base
  belongs_to :scholarship
  belongs_to :enrollment
  
  def to_label
    "#{start_date} - #{end_date}"
  end
  
  validates :scholarship, :presence => true
  validates :enrollment, :presence => true
  validate :start_date_greater_than_end_date
  validate :invalid_scholarship_duration_date
  validate :scholarship_with_another_student  
    
#  validation methods
  def scholarship_with_another_student    
    existing_scholarship_duration = ScholarshipDuration.find_by_scholarship_id(scholarship.id)   
    unless existing_scholarship_duration.nil?      
      if start_date.to_date < existing_scholarship_duration.end_date.to_date
        errors.add(:scholarship,I18n.t("activerecord.errors.scholarship_duration.already_associated_with_student"))        
      end
    end
  end
  
  def invalid_scholarship_duration_date
    unless scholarship.start_date.nil?
      if scholarship.start_date.to_date > start_date.to_date 
        errors.add(:start_date,I18n.t("activerecord.errors.scholarship_duration.start_date_smaller_than_scholarship_start_date"))
      end

      if scholarship.start_date.to_date > end_date.to_date
        errors.add(:end_date,I18n.t("activerecord.errors.scholarship_duration.end_date_smaller_than_scholarship_start_date"))
      end
    end
    
    unless scholarship.end_date.nil?
      if scholarship.end_date.to_date < start_date.to_date    
        errors.add(:start_date,I18n.t("activerecord.errors.scholarship_duration.start_date_greater_than_scholarship_end_date"))
      end    

      if scholarship.end_date.to_date < end_date.to_date
        errors.add(:end_date,I18n.t("activerecord.errors.scholarship_duration.end_date_greater_than_scholarship_end_date"))
      end 
    end
  end
  
  def start_date_greater_than_end_date
    if start_date.to_date > end_date.to_date
      errors.add(:start_date,I18n.t("activerecord.errors.scholarship_duration.start_date_greater_than_end_date"))
    end
  end
end

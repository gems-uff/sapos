class ScholarshipDuration < ActiveRecord::Base
  belongs_to :scholarship
  belongs_to :enrollment
  
  def to_label
    "#{start_date} - #{end_date}"
  end
  
  validate :start_date_greater_than_end_date
  
  def start_date_greater_than_end_date
    if start_date.to_date > end_date.to_date
      errors.add(:start_date,I18n.t("activerecord.errors.scholarship_duration.start_date_greater_than_end_date"))
    end
  end
end

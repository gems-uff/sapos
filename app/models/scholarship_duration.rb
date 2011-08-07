class ScholarshipDuration < ActiveRecord::Base
  belongs_to :scholarship
  belongs_to :enrollment
  
  def to_label
    "#{start_date} - #{end_date}"
  end
end

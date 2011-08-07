class Scholarship < ActiveRecord::Base
  belongs_to :level
  belongs_to :sponsor
  belongs_to :scholarship_type
  has_many :scholarship_durations
  has_many :enrollments, :through => :scholarship_durations
  
  def to_label
    "#{scholarship_number}"
  end
end

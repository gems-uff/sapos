class Scholarship < ActiveRecord::Base
  belongs_to :level
  belongs_to :sponsor
  belongs_to :scholarship_type
  belongs_to :professor
  has_many :scholarship_durations, :dependent => :destroy
  has_many :enrollments, :through => :scholarship_durations
  
  def to_label
    "#{scholarship_number}"
  end
  
  validates :scholarshio_number, :presence => true, :uniqueness => true
  
end

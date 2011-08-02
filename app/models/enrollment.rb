class Enrollment < ActiveRecord::Base
  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
  has_one :dismissal
  has_many :advisements
  has_many :professors, :through => :advisements
    
  def to_label
    "#{enrollment_number}"
  end
  
  validates_uniqueness_of :enrollment_number
end

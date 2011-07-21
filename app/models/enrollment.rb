class Enrollment < ActiveRecord::Base
  
  belongs_to :level
  belongs_to :enrollment_status
  has_one :dismissal
  belongs_to :student
  
  def to_label
    "#{enrollment_number}"
  end
end

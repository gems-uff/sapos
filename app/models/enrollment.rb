class Enrollment < ActiveRecord::Base
  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
  has_one :dismissal
    
  def to_label
    "#{enrollment_number}"
  end
end

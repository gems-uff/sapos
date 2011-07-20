class Enrollment < ActiveRecord::Base
  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
end

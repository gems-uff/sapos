class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment

  def to_label
    "#{enrollment.enrollment_number} - #{enrollment.student.name}"    
  end
end

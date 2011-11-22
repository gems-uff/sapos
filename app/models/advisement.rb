class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"    
  end
  
  validates :professor_id, :uniqueness => {:scope => :enrollment_id} #A professor can't be advisor more than once of an enrollment
  validates :main_advisor, :uniqueness => {:scope => :enrollment_id}
end

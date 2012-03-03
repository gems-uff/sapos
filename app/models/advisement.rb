class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"    
  end
  
  def enrollment_number
    return nil if enrollment.nil?
    return enrollment.enrollment_number
  end
  
  def student_name
    return nil if enrollment.nil?
    return nil if enrollment.student.nil?
    return enrollment.student.name
  end
  
  validates :professor_id, :uniqueness => {:scope => :enrollment_id} #A professor can't be advisor more than once of an enrollment
  validates :main_advisor, :uniqueness => {:scope => :enrollment_id}, :if => :main_advisor #only check if main_advisor is unique if the user tries to insert another main advisor
  validates :main_advisor, :presence => true, :if => :enrollment_has_no_advisors
  
  def enrollment_has_no_advisors
    return true if enrollment.nil?
    Advisement.find_all_by_enrollment_id(enrollment.id).empty?
  end
end

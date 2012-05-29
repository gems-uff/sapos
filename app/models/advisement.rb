class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"    
  end
  
  #defines if an certain advisement is active (An active advisement is an advisement which the student doesn't have a dismissal reason
  def active
    return false if enrollment.nil?
    dismissals = Dismissal.find(:all, :conditions => ["enrollment_id = ?",enrollment.id])
    return dismissals.empty?
  end
 
  def active_order
    return active.to_s
  end
  
  def co_advisor
      return false if enrollment.nil?
      co_advisors = Advisement.find(:all, :conditions => ["main_advisor = false and enrollment_id = ?", enrollment.id])
      return !co_advisors.empty?
  end
  
  def co_advisor_order
    return co_advisor.to_s
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

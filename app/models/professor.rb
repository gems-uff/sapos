class Professor < ActiveRecord::Base
  has_many :advisements, :dependent => :destroy
  has_many :enrollments, :through => :advisements
  has_many :scholarships, :dependent => :destroy

  validates :cpf, :presence => true, :uniqueness => true
  validates :name, :presence => true
  
#  It was considered that active advisements were enrollments without dismissals reasons
  def advisement_points
    enrollments_with_single_advisor = Enrollment.find(:all,
                                  :joins => ["LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id",:advisements],
                                  :conditions => ["advisements.professor_id = ? AND dismissals.id IS NULL AND  1 = (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id)",self.id])

    enrollments_with_multiple_advisors = Enrollment.find(:all,
                                  :joins => ["LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id",:advisements],
                                  :conditions => ["advisements.professor_id = ? AND dismissals.id IS NULL AND  1 < (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id)",self.id])
    
    points = 0
    enrollments_with_multiple_advisors.each { points += 0.5 }
    enrollments_with_single_advisor.each { points += 1 }
    
    "#{points.to_f.round(1)}"
  end
end
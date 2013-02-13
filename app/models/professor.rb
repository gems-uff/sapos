class Professor < ActiveRecord::Base
  has_many :advisements, :dependent => :destroy
  has_many :enrollments, :through => :advisements
  has_many :scholarships, :dependent => :destroy
  has_many :advisement_authorizations, :dependent => :destroy

  validates :cpf, :presence => true, :uniqueness => true
  validates :name, :presence => true
  
#  It was considered that active advisements were enrollments without dismissals reasons
  def advisement_points

    authorizated_levels = self.advisement_authorizations.map { |a| a.level_id}
    enrollments = Enrollment.joins(["LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id",:advisements]).
                  where("enrollments.level_id IN (:authorizated_levels)",:authorizated_levels => authorizated_levels).
                  where("advisements.professor_id = :professor_id AND dismissals.id IS NULL", :professor_id => self.id).scoped

    enrollments_with_single_advisor = enrollments.where("1 = (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id AND advisements.professor_id in (SELECT advisement_authorizations.professor_id from advisement_authorizations where advisement_authorizations.level_id = enrollments.level_id))")

    enrollments_with_multiple_advisors = enrollments.where("1 < (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id AND advisements.professor_id in (SELECT advisement_authorizations.professor_id from advisement_authorizations where advisement_authorizations.level_id = enrollments.level_id))")
    
    points = 0
    points += 0.5*enrollments_with_multiple_advisors.count +  enrollments_with_single_advisor.count

    "#{points.to_f.round(1)}"
  end

  def advisement_points_order
    advisement_points.to_f
  end
end
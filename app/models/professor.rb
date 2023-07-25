# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Professor < ApplicationRecord

  has_many :advisements, :dependent => :restrict_with_exception
  has_many :enrollments, :through => :advisements
  has_many :scholarships, :dependent => :restrict_with_exception
  has_many :advisement_authorizations, :dependent => :restrict_with_exception
  has_many :professor_research_areas, :dependent => :destroy
  has_many :research_areas, :through => :professor_research_areas
  has_many :course_classes, :dependent => :restrict_with_exception
  has_many :thesis_defense_committee_participations, :dependent => :restrict_with_exception
  has_many :thesis_defense_committee_enrollments, :source => :enrollment, :through => :thesis_defense_committee_participations
  
  belongs_to :city, optional: true
  belongs_to :institution, optional: true
  belongs_to :academic_title_country, optional: true, :class_name => 'Country', :foreign_key => 'academic_title_country_id' 
  belongs_to :academic_title_institution, optional: true, :class_name => 'Institution', :foreign_key => 'academic_title_institution_id'
  belongs_to :academic_title_level, optional: true, :class_name => 'Level', :foreign_key => 'academic_title_level_id'
  belongs_to :user, optional: true
    

  has_paper_trail

  validates :cpf, :presence => true, :uniqueness => true
  validates :name, :presence => true
  validates :email, :uniqueness => true, :allow_nil => true, :allow_blank => true
  validates :enrollment_number, :uniqueness => true, :allow_blank => true
  validate :changed_to_different_user

  def create_advisement_points_of_level_method(column_name)
    self.class.send(:define_method, column_name) {advisement_points(column_name[26..-1])}
  end

#  It was considered that active advisements were enrollments without dismissals reasons
  def advisement_points(level_id = nil)

    return "#{0.0}" if self.advisement_authorizations.empty?

    enrollments = Enrollment.joins(["LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id", :advisements]).
        where("advisements.professor_id = :professor_id AND dismissals.id IS NULL", :professor_id => self.id)

    if(level_id != nil)
      enrollments = enrollments.where(:level_id => level_id.to_i)
    end

    enrollments_with_single_advisor = enrollments.where("1 = (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id AND advisements.professor_id in (SELECT advisement_authorizations.professor_id from advisement_authorizations))")

    enrollments_with_multiple_advisors = enrollments.where("1 < (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id AND advisements.professor_id in (SELECT advisement_authorizations.professor_id from advisement_authorizations))")

    points = 0.0
    points += CustomVariable.multiple_advisor_points*enrollments_with_multiple_advisors.count + CustomVariable.single_advisor_points*enrollments_with_single_advisor.count

    "#{points.to_f}"
  end

  def advisement_points_order
    advisement_points.to_f
  end

  def advisement_point(enrollment)
    return 0.0 if self.advisement_authorizations.empty? || enrollment.advisements.where(:professor_id => self.id).empty? || enrollment.dismissal
    authorized_advisors = enrollment.advisements.joins(:professor).where("professors.id in (SELECT advisement_authorizations.professor_id from advisement_authorizations)").count
    (authorized_advisors.to_i == 1) ? CustomVariable.single_advisor_points : CustomVariable.multiple_advisor_points
  end

  def to_label
    "#{self.name}"
  end

  def changed_to_different_user
    if (user_id_changed?) && (!user_id.nil?) && (!user_id_was.nil?)	  
      errors.add(:user, :changed_to_different_user)
    end
  end

end

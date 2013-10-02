# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Professor < ActiveRecord::Base
  attr_accessible :name
  has_many :advisements, :dependent => :destroy
  has_many :enrollments, :through => :advisements
  has_many :scholarships, :dependent => :destroy
  has_many :advisement_authorizations, :dependent => :destroy

  validates :cpf, :presence => true, :uniqueness => true
  validates :name, :presence => true
  validates :enrollment_number, :uniqueness => true, :allow_blank => true

#  It was considered that active advisements were enrollments without dismissals reasons
  def advisement_points
    return "#{0.0}" if self.advisement_authorizations.empty?

    enrollments = Enrollment.joins(["LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id", :advisements]).
        where("advisements.professor_id = :professor_id AND dismissals.id IS NULL", :professor_id => self.id).scoped

    enrollments_with_single_advisor = enrollments.where("1 = (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id AND advisements.professor_id in (SELECT advisement_authorizations.professor_id from advisement_authorizations))")

    enrollments_with_multiple_advisors = enrollments.where("1 < (SELECT COUNT(*) FROM advisements WHERE advisements.enrollment_id = enrollments.id AND advisements.professor_id in (SELECT advisement_authorizations.professor_id from advisement_authorizations))")

    points = 0.0
    points += Configuration.multiple_advisor_points*enrollments_with_multiple_advisors.count + Configuration.single_advisor_points*enrollments_with_single_advisor.count

    "#{points.to_f}"
  end

  def advisement_points_order
    advisement_points.to_f
  end

  def advisement_point(enrollment)
    return 0.0 if self.advisement_authorizations.empty? || enrollment.advisements.where(:professor_id => self.id).empty? || enrollment.dismissal
    authorized_advisors = enrollment.advisements.joins(:professor).where("professors.id in (SELECT advisement_authorizations.professor_id from advisement_authorizations)").count
    (authorized_advisors.to_i == 1) ? Configuration.single_advisor_points : Configuration.multiple_advisor_points
  end

  def advisements_with_points
    #TODO Find out how to move this code to a helper
    return "-" if self.advisements.empty?

    body = ""
    count = 0
    total_point = 0.0
    self.advisements.joins([:enrollment, "LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id"]).where("dismissals.id IS NULL").each do |advisement|
      count +=1;
      tr_class = count.even? ? "even-record" : ""
      point = advisement_point(advisement.enrollment)
      total_point += point
      body += "<tr class=\"record #{tr_class}\">
                <td>#{advisement.enrollment.student.name}</td>
                <td>#{advisement.enrollment.enrollment_number}</td>
                <td>#{point}</td>
              </tr>"
    end
    body += "<tr class=\"record total_points\">
                <td colspan=2>#{I18n.t("active_scaffold.total_label")}</td>
                <td>#{total_point}</td>
              </tr>"


    resp = "<table style=\"border-collapse: collapse\">
              <thead style=\"color: white; font-size: 12px\">
                <tr>
                  <th style=\"padding-right: 15px\">#{I18n.t("activerecord.attributes.advisement.student_name")}</th>
                  <th style=\"padding-right: 15px\">#{I18n.t("activerecord.attributes.enrollment.enrollment_number")}</th>
                  <th style=\"padding-right: 15px\">#{I18n.t("activerecord.attributes.professor.advisement_points")}</th>
                </tr>
              </thead>
              <tboby class=\"records\">
              #{body}
              </tbody>
            </table>"
    resp.html_safe
  end
end
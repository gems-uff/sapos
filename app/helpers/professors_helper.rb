# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ProfessorsHelper
  def city_form_column(record, options)
    city_widget(
      record, options,
      country: :address_country, state: :address_state, city: :city,
      selected_city: record.city
    )
  end

  def identity_issuing_place_form_column(record, options)
    identity_issuing_place_widget(
      record, options,
      text: record.identity_issuing_place
    )
  end

  def professor_advisements_with_points_show_column(record, options)
    advisements = record.advisements.joins([:enrollment, "LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id"]).where("dismissals.id IS NULL")
    return "-" if advisements.empty?

    body = ""
    count = 0
    total_point = 0.0
    advisements.each do |advisement|
      count +=1;
      tr_class = count.even? ? "even-record" : ""
      point = record.advisement_point(advisement.enrollment)
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


    resp = "<table class=\"showtable listed-records-table\">
              <thead>
                <tr>
                  <th>#{I18n.t("activerecord.attributes.advisement.student_name")}</th>
                  <th>#{I18n.t("activerecord.attributes.enrollment.enrollment_number")}</th>
                  <th>#{I18n.t("activerecord.attributes.professor.advisement_points")}</th>
                </tr>
              </thead>
              <tboby class=\"records\">
              #{body}
              </tbody>
            </table>"
    resp.html_safe
  end

  def permit_rs_browse_params
    [:page, :update, :utf8]
  end

end

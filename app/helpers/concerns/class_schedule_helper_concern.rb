# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ClassScheduleHelperConcern
  def prepare_class_schedule_table(
    course_classes, on_demand, advisement_authorizations = nil,
    keep_on_demand = false, used_to_render_a_pdf_report: false
  )
    advisement_authorizations ||= []
    star = false
    first = 1
    last = 5
    course_classes.each do |course_class|
      course_class.allocations.each do |allocation|
        index = I18n.translate("date.day_names").index(allocation.day)
        unless index.nil?
          first = index if index < first
          last = index if index > last
        end
      end
    end
    header = [[
      "meta",
      "#{I18n.t("activerecord.attributes.class_schedule.table.course_name")}"
    ]]
    (first..last).each do |index|
      header[0] << "#{I18n.translate("date.day_names")[index]}"
    end
    header[0] << "#{I18n.t(
      "activerecord.attributes.class_schedule.table.professor"
    )}"

    table_data = []
    on_demand_professors = {}

    course_classes.each do |course_class|
      next if course_class.not_schedulable

      course_type = course_class.course.course_type
      next unless course_type.schedulable

      course = header[0].map { |x| [] }

      course[0] = {
        id: course_class.id, course_id: course_class.course_id,
        on_demand: course_type.on_demand
      }
      course[1] = used_to_render_a_pdf_report ?
        course_class.name_with_class_formated_to_reports :
        course_class.name_with_class

      course_class.allocations.each do |allocation|
        index = I18n.translate("date.day_names").index(allocation.day)
        course[index + 2 - first] << allocation.to_shortlabel
      end

      course = course.map { |x| x.kind_of?(Array) ? x.join("\n") : x }

      if course_class.allocations.empty?
        (first..last).each do |index|
          course[index + 2 - first] = "*\n "
        end
        star = true
      end

      course[-1] = rescue_blank_text(course_class.professor, method_call: :name)
      if ! course_type.on_demand || keep_on_demand
        table_data << course
      else
        (
          on_demand_professors[course_class.course_id] ||= []
        ) << course_class.professor
      end
    end

    demand_data = []

    on_demand.each do |course|
      professors = advisement_authorizations
      found_professors = on_demand_professors[course.id]
      if found_professors.present?
        different_professors = found_professors.filter do |prof|
          ! advisement_authorizations.include? prof
        end
        professors = different_professors + advisement_authorizations
      end
      next unless found_professors.present? || course.available

      course_data = header[0].map { |x| "" }
      course_data[0] = {
        id: nil, course_id: course.id,
        on_demand: true, professors: professors
      }
      course_data[1] = course.name
      (first..last).each do |index|
        course_data[index + 2 - first] = "*\n "
      end
      course_data[-1] = ""
      star = true
      demand_data << course_data
    end

    table_data += demand_data

    table_data.sort_by! { |e| e[1] }

    {
      star: star,
      first: first,
      last: last,
      header: header,
      data: table_data,
    }
  end
end

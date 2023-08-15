# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module CourseClassesPdfHelper
  def i18n_pdft(key, *args)
    key = "pdf_content.course_class." + key
    I18n.t(key, *args)
  end

  def summary_header(pdf, options = {})
    course_class ||= options[:course_class]

    widths = [576, 100, 130]

    top_header = [[
      "<b>#{i18n_pdft("summary.course_name").upcase}</b>",
      "<b>#{i18n_pdft("summary.year_semester").upcase}</b>",
      "<b>#{i18n_pdft("summary.lesson").upcase}</b>"
    ]]

    top_data = [[
      course_class.name_with_class_formated_to_reports,
      "#{course_class.semester}º/#{course_class.year}",
      ""
    ]]

    simple_pdf_table(pdf, widths, top_header, top_data) do |table|
      table.column(0).align = :left
      table.column(0).padding = [2, 4]
    end
  end

  def summary_table(pdf, options = {})
    course_class ||= options[:course_class]

    table_width = [30, 105]
    head = [
      "<b>#{i18n_pdft("summary.sequential_number")}</b>",
      "<b>#{i18n_pdft("summary.enrollment_number")}</b>",
      "<b>#{i18n_pdft("summary.student_name")}</b>",
    ]
    if course_class.course.course_type.has_score
      table_width.concat([285, 45])
      head << "<b>#{i18n_pdft("summary.final_grade")}</b>"
    else
      table_width << 330
    end
    table_width.concat([45, 60, 236])
    head.concat([
      "<b>#{i18n_pdft("summary.attendance")}</b>",
      "<b>#{i18n_pdft("summary.situation")}</b>",
      "<b>#{i18n_pdft("summary.obs")}</b>"
    ])
    header = [head]

    unless course_class.class_enrollments.empty?
      i = 0
      table_data = (
        course_class.class_enrollments
        .joins({ enrollment: :student })
        .order("students.name")
      ).map do |class_enrollment|
        row = []
        row << i += 1
        row << class_enrollment.enrollment.enrollment_number
        row << class_enrollment.enrollment.student.name +
          (class_enrollment.enrollment.has_active_scholarship_now? ? " *" : "")
        if course_class.course.course_type.has_score
          row << number_to_grade(class_enrollment.grade)
        end
        row << class_enrollment.attendance_to_label
        row << class_enrollment.situation == I18n.translate(
          "activerecord.attributes.class_enrollment.situations.registered"
        ) ? "" : class_enrollment.situation
        row << class_enrollment.obs
        row
      end
    else
      table_data = []
    end

    simple_pdf_table(
      pdf, table_width, header, table_data, distance: 0
    ) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
    end

    pdf.move_down 10
    pdf.text "<b>#{i18n_pdft(
      "summary.active_scholarship_table_footer_subtitle"
    )}</b>", inline_format: true

    pdf.move_down 50
  end

  def summary_footer(pdf, options = {})
    course_class ||= options[:course_class]

    line = "_________________________________________________________"
    pdf.text line, align: :center
    pdf.move_down 5
    pdf.font_size 10
    pdf.text "#{course_class.professor.name}", align: :center
  end

  def summary_emails_table(pdf, options = {})
    course_class ||= options[:course_class]

    table_width = [30, 105, 285, 386]

    header = [[
      "<b>#{i18n_pdft("summary.sequential_number")}</b>",
      "<b>#{i18n_pdft("summary.enrollment_number")}</b>",
      "<b>#{i18n_pdft("summary.student_name")}</b>",
      "<b>#{i18n_pdft("summary.student_email")}</b>"
    ]]

    unless course_class.class_enrollments.empty?
      i = 0
      table_data = (
        course_class.class_enrollments
          .joins({ enrollment: :student })
          .order("students.name")
      ).map do |class_enrollment|
        [
            i += 1,
            class_enrollment.enrollment.enrollment_number,
            class_enrollment.enrollment.student.name +
              (class_enrollment.enrollment.has_active_scholarship_now? ?
                " *" : ""),
            class_enrollment.enrollment.student.email
        ]
      end
    else
      table_data = []
    end

    simple_pdf_table(
      pdf, table_width, header, table_data, distance: 0
    ) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
      table.column(3).align = :left
      table.column(3).padding = [2, 4]
    end

    pdf.move_down 10
    pdf.text "<b>#{i18n_pdft(
      "summary.active_scholarship_table_footer_subtitle"
    )}</b>", inline_format: true
  end

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
      "#{i18n_pdft("class_schedule.course_name")}"
    ]]
    (first..last).each do |index|
      header[0] << "#{I18n.translate("date.day_names")[index]}"
    end
    header[0] << "#{i18n_pdft("class_schedule.professor")}"

    table_data = []
    on_demand_professors = {}

    course_classes.each do |course_class|
      next if course_class.not_schedulable

      course_type = course_class.course.course_type
      next unless course_type.schedulable

      course = header[0].map { |x| "" }

      course[0] = {
        id: course_class.id, course_id: course_class.course_id,
        on_demand: course_type.on_demand
      }
      course[1] = used_to_render_a_pdf_report ?
        course_class.name_with_class_formated_to_reports :
        course_class.name_with_class

      course_class.allocations.each do |allocation|
        index = I18n.translate("date.day_names").index(allocation.day)
        course[index + 2 - first] = allocation.to_shortlabel
      end

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

  def class_schedule_table(pdf, options = {})
    course_classes ||= options[:course_classes]
    on_demand ||= options[:on_demand]
    table = prepare_class_schedule_table(
      course_classes, on_demand, used_to_render_a_pdf_report: true
    )
    table[:header][0] = table[:header][0].drop(1).collect { |h| "<b>#{h}</b>" }
    table[:data] = table[:data].collect { |row| row.drop(1) }

    table_width = [286]
    count = table[:last] - table[:first] + 1
    day_width = (320 / count).floor
    (table[:first]..table[:last]).each do |index|
      table_width << day_width
    end
    table_width << (520 - day_width * count)

    count = 0
    rows_per_page = 15
    num_pages = (table[:data].size.to_f / rows_per_page).ceil

    table[:data].each_slice(rows_per_page) do |data_slice|
      count += 1
      last_page = (num_pages == count)
      class_schedule_print_table(
        pdf, table_width, table[:header], data_slice, table[:star], last_page
      )
      pdf.start_new_page unless last_page
    end
  end

  def class_schedule_print_table(pdf, table_width, header, data, star, footer)
    simple_pdf_table(pdf, table_width, header, data) do |table|
      table.column(0).align = :left
      table.column(0).valign = :center
      table.column(0).padding = [-2, 4, 2, 4]

      table.column(-1).align = :left
      table.column(-1).valign = :center
      table.column(-1).padding = [-2, 4, 2, 4]
    end

    class_schedule_text_print(pdf, star) if footer
  end

  def class_schedule_text_print(pdf, star)
    star_text = ""
    if star
      pdf.move_down 10
      pdf.text "<b>#{star_text}* #{
        i18n_pdft("class_schedule.noschedule")
      }</b>", inline_format: true
      star_text += "*"
    end

    unless CustomVariable.class_schedule_text.blank?
      pdf.move_down 5
      pdf.text "<b>#{star_text}* #{
        CustomVariable.class_schedule_text
      }</b>", inline_format: true
      # star_text += "*"
    end
  end
end

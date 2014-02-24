# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module CourseClassesPdfHelper

  def summary_header(pdf, options={})
    course_class ||= options[:course_class]

    widths = [576, 100, 130]

    top_header = [["<b>#{I18n.t("pdf_content.course_class.summary.course_name").upcase}</b>",
                   "<b>#{I18n.t("pdf_content.course_class.summary.year_semester").upcase}</b>",
                   "<b>#{I18n.t("pdf_content.course_class.summary.lesson").upcase}</b>"
                  ]]

    top_data = [[
                    course_class.course.name + (course_class.name.blank? ? '' : " (#{course_class.name})"),
                    "#{course_class.semester}º/#{course_class.year}",
                    ''
                ]]

    simple_pdf_table(pdf, widths, top_header, top_data) do |table|
      table.column(0).align = :left
      table.column(0).padding = [2, 4]
    end
  end

  def summary_table(pdf, options={})
    course_class ||= options[:course_class]

    table_width = [30, 105, 285, 45, 45, 60, 236]

    header = [["<b>#{I18n.t("pdf_content.course_class.summary.sequential_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.enrollment_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.student_name")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.final_grade")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.attendance")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.situation")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.obs")}</b>"]]

    unless course_class.class_enrollments.empty?
      i=0
      table_data = course_class.class_enrollments.joins({:enrollment => :student}).order("students.name").map do |class_enrollment|
        [
            i+=1,
            class_enrollment.enrollment.enrollment_number,
            class_enrollment.enrollment.student.name,
            number_to_grade(class_enrollment.grade),
            class_enrollment.attendance_to_label,
            class_enrollment.situation == I18n.translate("activerecord.attributes.class_enrollment.situations.registered") ? "" : class_enrollment.situation,
            class_enrollment.obs
        ]
      end
    else
      table_data = []
    end

    simple_pdf_table(pdf, table_width, header, table_data, distance: 0) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
    end


    pdf.move_down 50
  end

  def summary_footer(pdf, options={})
    course_class ||= options[:course_class]

    pdf.text '_________________________________________________________', :align => :center
    pdf.move_down 5
    pdf.font_size 10
    pdf.text "#{course_class.professor.name}", :align => :center
  end

  def summary_emails_table(pdf, options={})
    course_class ||= options[:course_class]

    table_width = [30, 105, 285, 386]

    header = [["<b>#{I18n.t("pdf_content.course_class.summary.sequential_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.enrollment_number")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.student_name")}</b>",
               "<b>#{I18n.t("pdf_content.course_class.summary.student_email")}</b>"]]

    unless course_class.class_enrollments.empty?
      i=0
      table_data = course_class.class_enrollments.joins({:enrollment => :student}).order("students.name").map do |class_enrollment|
        [
            i+=1,
            class_enrollment.enrollment.enrollment_number,
            class_enrollment.enrollment.student.name,
            class_enrollment.enrollment.student.email
        ]
      end
    else
      table_data = []
    end

    simple_pdf_table(pdf, table_width, header, table_data, distance: 0) do |table|
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
      table.column(3).align = :left
      table.column(3).padding = [2, 4]
    end
  end

  def class_schedule_table(pdf, options={})
    course_classes ||= options[:course_classes]
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

    table_width = [286]
    header = [[
      "<b>#{I18n.t("pdf_content.course_class.class_schedule.course_name")}</b>"
    ]]

    count = last - first + 1
    day_width = (320 / count).floor
    (first..last).each do |index|
      table_width << day_width
      header[0] << "<b>#{I18n.translate("date.day_names")[index]}</b>"
    end
    table_width << (520 - day_width * count)
    header[0] << "<b>#{I18n.t("pdf_content.course_class.class_schedule.professor")}</b>"

    table_data = []

    course_classes.each do |course_class|
      next unless course_class.course.course_type.schedulable
        
      course = header[0].map {|x| ""}
      course_name = rescue_blank_text(course_class.course, :method_call => :name)

      if course_class.name.nil? or course_class.name.empty? or not course_class.course.course_type.show_class_name
        course[0] = course_name
      else
        course[0] = "#{course_name} (#{course_class.name})"
      end

      course_class.allocations.each do |allocation| 
        index = I18n.translate("date.day_names").index(allocation.day)
        course[index + 1 - first] = "#{allocation.start_time}-#{allocation.end_time}"
        course[index + 1 - first] += "\n#{allocation.room || ' '}"
      end

      if course_class.allocations.empty?
        (first..last).each do |index|
          table_width << day_width
          course[index + 1 - first] = "*\n "
        end
        star = true
      end

      course[-1] = rescue_blank_text(course_class.professor, :method_call => :name)
      table_data << course
    end

    table_data.sort_by! { |e| e[0] }

    temp_data = []
    total = 0
    count = 0

    table_data.each do |data| 
      total += 1
      count += 1
      temp_data << data

      if count == 15
        class_schedule_print_table(pdf, table_width, header, temp_data, star)
        if total != table_data.size
          pdf.start_new_page
        end
        temp_data = []
        count = 0
      end
    end

    unless temp_data.empty?
      class_schedule_print_table(pdf, table_width, header, temp_data, star)
    end
    
  end

  def class_schedule_print_table(pdf, table_width, header, data, star)
    simple_pdf_table(pdf, table_width, header, data) do |table|
      table.column(0).align = :left
      table.column(0).valign = :center
      table.column(0).padding = [-2, 4, 2, 4]
      
      table.column(-1).align = :left
      table.column(-1).valign = :center
      table.column(-1).padding = [-2, 4, 2, 4]    
    end

    star_text = ""
    if star
      pdf.move_down 10
      pdf.text "<b>#{star_text}* #{I18n.t("pdf_content.course_class.class_schedule.noschedule")}</b>", :inline_format => true
      star_text += "*"
    end

    unless CustomVariable.class_schedule_text.nil? or CustomVariable.class_schedule_text.empty? 
      pdf.move_down 5
      pdf.text "<b>#{star_text}* #{CustomVariable.class_schedule_text}</b>", :inline_format => true
      star_text += "*"
    end
  end

end

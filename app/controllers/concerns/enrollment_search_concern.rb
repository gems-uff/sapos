# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module EnrollmentSearchConcern
  extend ActiveSupport::Concern

  class_methods do
    def add_enrollment_number_search_column(config)
      config.columns[:enrollment_number].search_ui = :select
    end

    def add_student_search_column(config)
      config.columns[:student].search_sql = "enrollments.student_id"
      config.columns[:student].search_ui = :select
    end

    def add_enrollment_level_search_column(config)
      config.columns[:enrollment_level].search_sql = "enrollments.level_id"
      config.columns[:enrollment_level].search_ui = :select
    end

    def add_enrollment_status_search_column(config)
      config.columns[:enrollment_status].search_sql =
        "enrollments.enrollment_status_id"
      config.columns[:enrollment_status].search_ui = :select
    end

    def add_admission_date_search_column(config)
      config.columns[:admission_date].search_sql = "enrollments.admission_date"
      config.columns[:admission_date].options = { format: :monthyear }
    end

    def add_scholarship_durations_active_search_column(config)
      config.columns[:scholarship_durations_active].search_sql = ""
      config.columns[:scholarship_durations_active].search_ui = :select
    end

    def add_advisor_search_column(config)
      config.columns[:advisor].search_sql = "advisements.professor_id"
      config.columns[:advisor].search_ui = :select
    end

    def add_has_advisor_search_column(config)
      config.columns[:has_advisor].search_sql = ""
      config.columns[:has_advisor].search_ui = :select
    end

    def add_course_type_search_column(config)
      config.columns[:course_type].search_sql = "course_types.id"
      config.columns[:course_type].search_ui = :select
    end

    def add_professor_search_column(config)
      config.columns[:professor].search_sql = "professors.id"
      config.columns[:professor].search_ui = :select
    end

    def custom_condition_for_admission_date_column(column, value, like_pattern)
      month = value[:month].blank? ? 1 : value[:month]
      year = value[:year].blank? ? 1 : value[:year]

      if year != 1
        date1 = Date.new(year.to_i, month.to_i)
        date2 = Date.new(
          month.to_i == 12 ? year.to_i + 1 : year.to_i,
          (month.to_i % 12) + 1
        )

        [
          "DATE(#{column.search_sql.last}) >= ?
           and DATE(#{column.search_sql.last}) < ?",
           date1, date2
        ]
      end
    end

    def custom_condition_for_scholarship_durations_active_column(
      column, value, like_pattern
    )
      query_active_scholarships = "
        select enrollment_id
        from scholarship_durations
        where DATE(scholarship_durations.end_date) >= DATE(?)
        AND (
          scholarship_durations.cancel_date is NULL
          OR DATE(scholarship_durations.cancel_date) >= DATE(?)
        )
      "
      case value
      when "0" then
        sql = "enrollments.id not in (#{query_active_scholarships})"
      when "1" then
        sql = "enrollments.id in (#{query_active_scholarships})"
      else
        return ""
      end
      [sql, Time.now, Time.now]
    end

    def custom_condition_for_has_advisor_column(column, value, like_pattern)
      query_advisements = "select enrollment_id from advisements"
      case value
      when "0" then
        sql = "enrollments.id not in (#{query_advisements})"
      when "1" then
        sql = "enrollments.id in (#{query_advisements})"
      else
        return ""
      end
      [sql]
    end

    def custom_condition_for_accomplishments_column(column, value, like_pattern)
      return "" if value[:phase].blank?
      date = value.nil? ? value : "#{value[:year]}-#{
        (value[:month].size == 1) ? "0" + value[:month] : value[:month]
      }-#{(value[:day].size == 1) ? "0" + value[:day] : value[:day]}"
      phase = value[:phase] == "all" ? nil : value[:phase]
      if value[:phase] == "all"
        enrollments_ids = Enrollment.with_all_phases_accomplished_on(date)
        query = enrollments_ids.blank? ? "1 = 2" : "enrollments.id in (#{
          enrollments_ids.join(",")
        })"
      else
        query = "enrollments.id in (
          select enrollment_id
          from accomplishments
          where DATE(conclusion_date) <= DATE('#{date}')
          and phase_id = #{phase}
        )"
      end
      query
    end

    def custom_condition_for_active_column(column, value, like_pattern)
      query_inactive_enrollment = "
        select enrollment_id
        from dismissals
        where DATE(dismissals.date) <= DATE(?)
      "
      case value
      when "not_active" then
        sql = "enrollments.id in (#{query_inactive_enrollment})"
      when "active" then
        sql = "enrollments.id not in (#{query_inactive_enrollment})"
      else
        return ""
      end
      [sql, Time.now]
    end

    def custom_condition_for_course_class_year_semester_column(
      column, value, like_pattern
    )
      return [] if value[:year].empty? &&
        value[:semester].empty? &&
        value[:course].empty?
      result = []

      search_sql = " enrollments.id in (
        select class_enrollments.enrollment_id
        from class_enrollments, course_classes
        where course_classes.id = class_enrollments.course_class_id
      "

      if !value[:course].empty?
        search_sql += " and course_classes.course_id in (?) "
        result << Course.ids_de_disciplinas_com_nome_parecido(value[:course])
      end

      if !value[:year].empty?
        search_sql += " and course_classes.year = ? "
        result << value[:year]
      end

      if !value[:semester].empty?
        search_sql += " and course_classes.semester = ? "
        result << value[:semester]
      end

      search_sql += " ) "

      [ search_sql ] + result
    end

    def custom_condition_for_delayed_phase_column(column, value, like_pattern)
      return "" if value[:phase].blank?
      date = value.nil? ? value : Date.parse(
        "#{value[:year]}/#{value[:month]}/#{value[:day]}"
      )
      phase = value[:phase] == "all" ? Phase.all : [Phase.find(value[:phase])]
      enrollments_ids = Enrollment.with_delayed_phases_on(date, phase)
      query_delayed_phase = enrollments_ids.blank? ? "1 = 2" : "
        enrollments.id in (#{enrollments_ids.join(',')})
      "
      query_delayed_phase
    end

    def custom_condition_for_enrollment_hold_column(column, value, like_pattern)
      return "" if value[:hold].blank? || value[:hold].to_i == 0
      eh = EnrollmentHold.arel_table
      enrollments_ids = Enrollment.joins(:enrollment_holds)
        .where(eh[:active].eq(true)).pluck(:id)
      query_enrollment_hold = enrollments_ids.blank? ? "1 = 2" : "
        enrollments.id in (#{enrollments_ids.join(',')})"
      query_enrollment_hold
    end
  end
end

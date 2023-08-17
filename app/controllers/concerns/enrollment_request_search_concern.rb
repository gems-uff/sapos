# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module EnrollmentRequestSearchConcern
  extend ActiveSupport::Concern
  class_methods do
    def add_year_search_column(config)
      config.columns[:year].search_ui = :select
      config.columns[:year].options = {
        options: YearSemester.selectable_years,
        include_blank: true,
        default: nil
      }
    end

    def add_semester_search_column(config)
      config.columns[:semester].search_ui = :select
      config.columns[:semester].options = {
        options: YearSemester::SEMESTERS,
        include_blank: true,
        default: nil
      }
    end

    def custom_condition_for_status(value, exists, not_exists, check_parent)
      invalid = "
        select cer.enrollment_request_id
        from class_enrollment_requests cer
        where cer.status = '#{ClassEnrollmentRequest::INVALID}'#{check_parent}
      "
      valid = "
        select cer.enrollment_request_id
        from class_enrollment_requests cer
        where cer.status = '#{ClassEnrollmentRequest::VALID}'#{check_parent}
      "
      not_valid = "
        select cer.enrollment_request_id
        from class_enrollment_requests cer
        where cer.status != '#{ClassEnrollmentRequest::VALID}'
        and cer.status != '#{ClassEnrollmentRequest::EFFECTED}'#{check_parent}
      "
      not_effected = "
        select cer.enrollment_request_id
        from class_enrollment_requests cer
        where cer.status != '#{ClassEnrollmentRequest::EFFECTED}'#{check_parent}
      "
      case value
      when ClassEnrollmentRequest::INVALID then
        sql = "#{exists} (#{invalid})"
      when ClassEnrollmentRequest::VALID then
        sql = "#{not_exists} (#{not_valid}) and #{exists} (#{valid})"
      when ClassEnrollmentRequest::EFFECTED then
        sql = "#{not_exists} (#{not_effected})"
      when ClassEnrollmentRequest::REQUESTED then
        sql = "#{not_exists} (#{invalid}) and #{exists} (#{not_valid})"
      else
        return ""
      end
      [sql]
    end
  end
end

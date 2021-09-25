# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentRequestsHelper
  
  include EnrollmentSearchHelperConcern

  def class_request_attribute(record, column_status)
    record_status = record.status
    result = [
      'type="radio"',
      "value=\"#{column_status}\""
    ]
    checked = column_status == record_status
    result << 'checked="checked"' if checked
    classes = ["class-enrollment-request-status", "radio-#{column_status.parameterize}"]

    if (column_status == ClassEnrollmentRequest::EFFECTED && cannot?(:effect, record)) || cannot?(:update, record)
      result << 'readonly="readonly"'
      result << 'disabled="disabled"' unless checked
    end

    classes << 'effected-item' if record_status == ClassEnrollmentRequest::EFFECTED
    result << "class=\"#{classes.join(' ')}\""
    result.join(' ').html_safe
  end

  alias_method :student_search_column, :custom_student_search_column
  alias_method :enrollment_level_search_column, :custom_enrollment_level_search_column
  alias_method :enrollment_status_search_column, :custom_enrollment_status_search_column
  alias_method :admission_date_search_column, :custom_admission_date_search_column
  alias_method :scholarship_durations_active_search_column, :custom_scholarship_durations_active_search_column
  alias_method :advisor_search_column, :custom_advisor_search_column
  alias_method :has_advisor_search_column, :custom_has_advisor_search_column
  alias_method :professor_search_column, :custom_professor_search_column
  
  def class_enrollment_requests_show_column(record, column)
    return "-" if record.class_enrollment_requests.nil?

    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.class_enrollment_request.action')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment_request.status')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment_request.course_class')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment_request.allocations')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment_request.professor')}</th>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.class_enrollment_requests.each do |cer|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                  <td>#{cer.action}</td>
                  <td>#{cer.status}</td>
                  <td>#{cer.course_class.to_label}</td>
                  <td>#{cer.allocations}</td>
                  <td>#{cer.professor}</td>
                </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def enrollment_request_comments_show_column(record, column)
    return "-" if record.enrollment_request_comments.nil?

    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.enrollment_request_comment.user')}</th>
                <th>#{I18n.t('activerecord.attributes.enrollment_request_comment.message')}</th>
                <th>#{I18n.t('activerecord.attributes.enrollment_request_comment.created_at')}</th>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.enrollment_request_comments.each do |comment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                  <td>#{comment.user.to_label}</td>
                  <td>#{comment.message}</td>
                  <td>#{comment.created_at}</td>
                </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

end
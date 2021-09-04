# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentRequestsHelper

  def class_request_attribute(column_status, record_status)
    result = [
      'type="radio"',
      "value=\"#{column_status}\""
    ]
    checked = column_status == record_status
    if checked
      result << 'checked="checked"'
    end
    if [column_status, record_status].include?(ClassEnrollmentRequest::EFFECTED)
      result << 'readonly="readonly"'
      unless checked
        result << 'disabled="disabled"'
      end
    else
      result << "class=\"class-enrollment-request-status-radio radio-#{column_status.parameterize}\""
    end
    result.join(' ').html_safe
  end

  def class_enrollment_requests_show_column(record, column)
    return "-" if record.class_enrollment_requests.nil?

    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
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
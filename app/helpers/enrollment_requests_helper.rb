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


end
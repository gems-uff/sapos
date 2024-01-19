# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionReportColumnsHelper
  def name_form_column(record, options)
    form_field_name_widget(record, options, text: record.name, query_options: {
      in_letter: true
    })
  end
end

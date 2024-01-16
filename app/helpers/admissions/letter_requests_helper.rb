# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::LetterRequestsHelper
  def access_token_column(record, column)
    if can?(:manage, record)
      link_to record.access_token, admission_letter_url(
        admission_id: record.admission_application.admission_process.simple_id,
        id: record.access_token
      )
    else
      record.access_token
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionApplicationsHelper
  def letter_requests_column(record, column)
    if record.letter_requests.any?
      "#{record.letter_requests.first(3).filter_map do |letter|
           h(letter.to_label) if letter.filled_form.is_filled
         end.join(', ')} / #{record.requested_letters}".html_safe
    else
      active_scaffold_config.list.empty_field_text
    end
  end
end

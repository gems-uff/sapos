# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module AdvisementAuthorizationsHelper
  def professor_form_column(record, options)
    record_select_field :professor, record.professor || Professor.new, options
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module GrantsHelper
  def professor_form_column(record, options)
    if can?(:edit_professor, record)
      record_select_field :professor, record.professor || Professor.new, options
    else
      options[:value] = record.professor_id
      label(
        :record_value_1_params, record.id, record.professor.name
      ) + hidden_field(:record, :professor, options)
    end
  end
end

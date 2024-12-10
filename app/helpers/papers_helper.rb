# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module PapersHelper
  def owner_form_column(record, options)
    if can?(:edit_professor, record)
      record_select_field :owner, record.owner || Professor.new, options
    else
      options[:value] = record.owner_id
      label(
        :record_value_1_params, record.id, record.owner.name
      ) + hidden_field(:record, :owner, options)
    end
  end

  def period_form_column(record, options)
    if can?(:edit_professor, record)
      text_field :record, :period, options
    else
      label(
        :record_value_1_params, record.id, record.period
      ) + hidden_field(:record, :period, options)
    end
  end

  def reason_group_form_column(record, options)
    "aaaa"
  end
end
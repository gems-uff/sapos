# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AllocationsController < ApplicationController
  authorize_resource

  active_scaffold :allocation do |config|
    config.list.columns = [:course_class, :day, :room, :start_time, :end_time]
    config.create.label = :create_allocation_label

    config.columns[:course_class].form_ui = :record_select
    config.columns[:day].form_ui = :select
    config.columns[:day].options = {
      options: I18n.translate("date.day_names"),
      include_blank: I18n.t("active_scaffold._select_")
    }

    config.columns = [
      :course_class, :day, :room, :start_time, :end_time
    ]

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name], order_by: "name", full_text_search: true
  )
end

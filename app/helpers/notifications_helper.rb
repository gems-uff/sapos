# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module NotificationsHelper
  def query_sql_form_column(record, options)
    code_mirror_view_widget(
      "sql_query-view-#{record.id}", "text/x-mysql",
      (record.query.try(:sql) || ""), true
    )
  end

  def body_template_form_column(record, options)
    code_mirror_text_area_widget(
      :body_template, "record_body_template_#{record.id}", "text/html",
      options.merge(
        value: record.body_template ||
        I18n.t("active_scaffold.notification.body_template_default")
      )
    )
  end

  def next_execution_column(record, options)
    return "-" if record.blank?
    return "-" if record.next_execution.nil?
    return "-" if record.frequency == Notification::MANUAL
    I18n.localize(record.next_execution, format: :day)
  end

  def sql_query_show_column(record, column)
    code_mirror_view_widget(
      "sql_query-view-#{record.id}", "text/x-mysql",
      (record.query.try(:sql) || "")
    )
  end

  def body_template_show_column(record, column)
    code_mirror_view_widget(
      "body_template-view-#{record.id}", "text/html", record.body_template
    )
  end

  def notification_param_query_param_form_column(record, options)
    options[:value] = record.query_param_id
    label(
      :record_value_1_params, record.id,
      ("(#{record.value_type}) ") + record.name
    ) + hidden_field(:record, :query_param, options)
  end
end

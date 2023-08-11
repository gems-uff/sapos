# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module QueriesHelper
  def sql_form_column(record, options)
    options[:required] = false
    code_mirror_text_area_widget(
      :sql_query, "record_sql_#{record.id}", "text/x-mysql", options.merge(
        value: record.sql ||
        I18n.t("active_scaffold.notification.sql_query_default")
      )
    )
  end

  def body_template_form_column(record, options)
    options[:required] = false
    code_mirror_text_area_widget(
      :body_template, "record_body_template_#{record.id}", "text/html",
      options.merge(
        value: record.body_template ||
        I18n.t("active_scaffold.notification.body_template_default")
      )
    )
  end
end

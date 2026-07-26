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
    columns = record.available_columns
    unique_columns = record.available_unique_columns
    roles = Role.pluck(:name)
    formats = I18n.t("time.formats")
    formats_filtered = formats.select { |key, value| value.is_a?(String) }
    code_mirror_text_area_widget(
      :body_template, "record_body_template_#{record.id}", "liquid",
      options.merge(
        value: record.body_template ||
        I18n.t("active_scaffold.notification.body_template_default_liquid")
      ),
      set_size = 35,
      line_wrapping = true,
      local = "notifications",
      columns: columns,
      unique_columns: unique_columns,
      roles: roles,
      formats: formats_filtered
    )
  end

  # Markup kept in the preview of a message: what a template may write and a
  # mail client may render, including the legacy markup that mail clients
  # still support, such as <font> and the presentational attributes of a
  # table.
  #
  # What is left out is what a mail client does not render anyway and would
  # only act on this page: <script>, <iframe>, <object>, <form> and <style>.
  # The <style> tag is worth a note, because a mail client does render it: its
  # rules are not scoped to the preview, so a body could restyle the whole
  # administration page around it.
  PREVIEW_TAGS = %w[
    a b big blockquote br caption center code col colgroup dd del div dl dt em
    font h1 h2 h3 h4 h5 h6 hr i img ins li ol p pre s small span strike strong
    sub sup table tbody td tfoot th thead tr u ul
  ].freeze
  PREVIEW_ATTRIBUTES = %w[
    align alt bgcolor border cellpadding cellspacing color colspan dir face
    height href rowspan size span src style target title valign width
  ].freeze

  # Renders the body of a simulated message the same way it is delivered.
  #
  # The simulation exists to show what the recipient is going to read, so the
  # body goes through the very same conversion that Notifier applies to the
  # html part of a message.
  #
  # The body is markup written by the author of the template, and the preview
  # is the only place where it reaches a browser: a mail client does not run
  # scripts and prawn does not even understand them. It is sanitized here so
  # that showing a message cannot run what the message carries, which is also
  # closer to what the recipient reads, because mail clients sanitize as well.
  def notification_body_preview(body)
    sanitized = sanitize(
      body.to_s, tags: PREVIEW_TAGS, attributes: PREVIEW_ATTRIBUTES
    )
    Notifier.body_whitespace_to_html(sanitized).html_safe
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
      "body_template-view-#{record.id}", "liquid", record.body_template
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

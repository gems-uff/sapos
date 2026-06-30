# app/helpers/assertions_helper.rb
module AssertionsHelper
  include PdfHelper
  include AssertionsPdfHelper

  def query_sql_form_column(record, options)
    code_mirror_view_widget(
      "sql_query-view-#{record.id}", "text/x-mysql",
      (record.query.try(:sql) || ""), true
    )
  end

  def assertion_template_form_column(record, options)
    columns = record.available_columns
    unique_columns = record.available_unique_columns
    roles = Role.pluck(:name)
    formats = I18n.t("time.formats")
    formats_filtered = formats.select { |key, value| value.is_a?(String) }
    code_mirror_text_area_widget(
      :assertion_template, "record_assertion_template_#{record.id}", "liquid",
      options.merge(
        value: record.assertion_template ||
          I18n.t("active_scaffold.notification.body_template_default_liquid"),
      ),
      set_size = 35,
      line_wrapping = true,
      local = "assertions",
      columns: columns,
      unique_columns: unique_columns,
      roles: roles,
      formats: formats_filtered
    )
  end

  def expiration_in_months_form_column(record, options)
    merge_options = { min: 1, value: record.new_record? ? ReportConfiguration.where(use_at_assertion: true).order(order: :desc).first&.expiration_in_months : record.expiration_in_months }
    number_field :record, :expiration_in_months, options.merge!(merge_options)
  end
end

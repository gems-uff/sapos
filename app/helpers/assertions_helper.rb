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
    code_mirror_text_area_widget(
      :assertion_template, "record_assertion_template_#{record.id}", "text/html",
      options.merge(
        value: record.assertion_template ||
          I18n.t("active_scaffold.notification.body_template_default")
      )
    )
  end

end

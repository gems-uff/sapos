# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module EmailTemplatesHelper
  def body_form_column(record, options)
    code_mirror_text_area_widget(
      :body, "record_body_#{record.id}", "text/html", options.merge(
        value: record.body || I18n.t("email_template.body.default")
      )
    )
  end

  def body_show_column(record, column)
    code_mirror_view_widget("body-view-#{record.id}", "text/html", record.body)
  end
end

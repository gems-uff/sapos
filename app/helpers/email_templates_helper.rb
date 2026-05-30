# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module EmailTemplatesHelper
  def body_form_column(record, options)
    code_mirror_text_area_widget(
      :body, "record_body_#{record.id}", "liquid", options.merge(
        value: record.body || I18n.t("email_template.body.default")
      ),
      set_size=35,
      line_wrapping=true
    )
  end

  def body_show_column(record, column)
    code_mirror_view_widget("body-view-#{record.id}", "liquid", record.body)
  end
end

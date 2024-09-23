# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document(
  "assertion.pdf",
  I18n.t("pdf_content.assertion.assertion_pdf.filename"),
  pdf_type: :assertion
) do |pdf|
  assertion_table(
      pdf, assertion: @assertion
    )

end
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document("to_pdf.pdf", admission_process_pdf_t("short_pdf.filename"), pdf_type: :report) do |pdf|
  admission_applications_table(pdf, admission_process: @admission_process)
  pdf.font("Courier", size: 8) do
    options = {
      at: [pdf.bounds.right - 100, -10],
      width: 100,
      align: :right
    }
    pdf.number_pages "#{admission_process_pdf_t("footer.page")}<page>/<total>", options
  end
end

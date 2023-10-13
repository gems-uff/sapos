# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document("to_pdf.pdf", admission_process_pdf_t("complete_pdf.filename"), pdf_type: :report) do |pdf|
  admission_applications_complete_table(pdf, admission_process: @admission_process)
end

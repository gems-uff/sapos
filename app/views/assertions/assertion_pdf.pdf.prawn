# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document(
  "assertion.pdf",
  "Assertion",
  pdf_type: :assertion
) do |pdf|
  pdf.text "Query Results for #{assertion.name}", size: 18, style: :bold
  pdf.move_down 20

  pdf.text "SQL Query:", size: 14, style: :bold
  pdf.text query_result[:query]
  pdf.move_down 20

  pdf.text "Results:", size: 14, style: :bold
  pdf.table([query_result[:columns]] + query_result[:rows], header: true)
end
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document(
  "assertion.pdf",
  "Assertion",
  pdf_type: :assertion
) do |pdf|
  pdf.text "SQL Query:", size: 14, style: :bold

end
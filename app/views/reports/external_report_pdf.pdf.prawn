# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "prawn/measurement_extensions"

new_document(
  @report.file_name,
  @title,
  override: { signature_type: :qr_code, expiration_in_months: @expiration_in_months },
  pdf_type: :assertion,
  report: @report
) do |pdf|
  report_body_text(pdf, @document_body)
end

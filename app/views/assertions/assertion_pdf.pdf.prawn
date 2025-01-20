# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document(
  @filename,
  I18n.t("pdf_content.assertion.assertion_pdf.filename"),
  watermark: cannot?(
    :generate_report_without_watermark, Enrollment
  ),
  pdf_type: :assertion,
  override: if can?(:override_report_signature_type, Assertion)
              { signature_type: @signature_override }.compact.merge({ expiration_in_months: @assertion.expiration_in_months })
            else
              { expiration_in_months: @assertion.expiration_in_months }
            end
) do |pdf|
  assertion_table(
      pdf, assertion: @assertion
    )
end

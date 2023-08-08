# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document(
  "preview.pdf",
  I18n.t("pdf_content.report_configurations.preview"),
  pdf_config: @pdf_config
) do |pdf|
end

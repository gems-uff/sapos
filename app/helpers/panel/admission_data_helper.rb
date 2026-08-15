# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Panel::AdmissionDataHelper
  def is_open_column(record, column)
    if record.is_open?
      I18n.t("panel.admission_data.status_open")
    else
      I18n.t("panel.admission_data.status_closed")
    end
  end

  def total_file_size_column(record, column)
    size_in_mb = record.total_file_size
    return "-" if size_in_mb.nil? || size_in_mb == 0
    "#{size_in_mb} MB"
  end
end

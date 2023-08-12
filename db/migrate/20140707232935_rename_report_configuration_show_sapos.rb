# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RenameReportConfigurationShowSapos < ActiveRecord::Migration[5.1]
  def change
    rename_column :report_configurations, :show_sapos, :signature_footer
  end
end

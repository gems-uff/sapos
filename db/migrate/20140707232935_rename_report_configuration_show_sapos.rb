# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RenameReportConfigurationShowSapos < ActiveRecord::Migration
  def change
  	rename_column :report_configurations, :show_sapos, :signature_footer
  end
end

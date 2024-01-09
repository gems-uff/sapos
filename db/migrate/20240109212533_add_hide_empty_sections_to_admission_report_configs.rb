# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddHideEmptySectionsToAdmissionReportConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_report_configs, :hide_empty_sections, :boolean
    add_column :admission_report_configs, :show_partial_candidates, :boolean
  end
end

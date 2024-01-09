# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionReportConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_report_configs do |t|
      t.string :name
      t.integer :form_template_id
      t.integer :form_condition_id
      t.string :group_column_tabular
      t.string :group_column_simple_pdf
      t.string :group_column_complete_pdf

      t.timestamps
    end
    add_index :admission_report_configs, :form_template_id
    add_index :admission_report_configs, :form_condition_id
  end
end

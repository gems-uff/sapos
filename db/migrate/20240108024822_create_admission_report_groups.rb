# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionReportGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_report_groups do |t|
      t.integer :admission_report_config_id
      t.integer :order
      t.string :mode
      t.string :operation
      t.string :committee

      t.timestamps
    end
    add_index :admission_report_groups, :admission_report_config_id
  end
end

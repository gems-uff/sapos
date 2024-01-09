# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionReportColumn < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_report_columns do |t|
      t.integer :admission_report_group_id
      t.integer :order
      t.string :name

      t.timestamps
    end
    add_index :admission_report_columns, :admission_report_group_id
  end
end

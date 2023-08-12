# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateReportConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :report_configurations do |t|
      t.string :name
      t.boolean :use_at_report
      t.boolean :use_at_transcript
      t.boolean :use_at_grades_report
      t.boolean :use_at_schedule
      t.text :text
      t.string :image
      t.boolean :show_sapos
      t.integer :order, default: 2
      t.decimal :scale
      t.integer :x
      t.integer :y
      t.timestamps
    end
  end
end

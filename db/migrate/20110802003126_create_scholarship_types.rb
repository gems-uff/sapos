# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateScholarshipTypes < ActiveRecord::Migration[5.1]
  def self.up
    create_table :scholarship_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :scholarship_types
  end
end

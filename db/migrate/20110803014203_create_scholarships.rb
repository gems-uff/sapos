# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateScholarships < ActiveRecord::Migration
  def self.up
    create_table :scholarships do |t|
      t.string :scholarship_number
      t.references :level
      t.references :sponsor
      t.references :scholarship_type
      t.date :start_date
      t.date :end_date
      t.text :obs

      t.timestamps
    end
  end

  def self.down
    drop_table :scholarships
  end
end

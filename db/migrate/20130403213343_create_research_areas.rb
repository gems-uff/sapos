# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateResearchAreas < ActiveRecord::Migration[5.1]
  def self.up
    create_table :research_areas do |t|
      t.string :name
      t.string :code

      t.timestamps
    end
  end

  def self.down
    drop_table :research_areas
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateProfessorResearchAreas < ActiveRecord::Migration[5.1]
  def self.up
    create_table :professor_research_areas do |t|
      t.references :professor
      t.references :research_area

      t.timestamps
    end
  end

  def self.down
    drop_table :professor_research_areas
  end
end

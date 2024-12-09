# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreatePaperProfessors < ActiveRecord::Migration[7.0]
  def change
    create_table :paper_professors do |t|
      t.references :paper, null: false, foreign_key: true
      t.references :professor, null: false, foreign_key: true

      t.timestamps
    end
  end
end

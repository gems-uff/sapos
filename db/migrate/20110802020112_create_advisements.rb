# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateAdvisements < ActiveRecord::Migration
  def self.up
    create_table :advisements do |t|
      t.references :professor, :null => false
      t.references :enrollment, :null => false
      t.boolean :main_advisor

      t.timestamps
    end
    
    add_index :advisements, :professor_id
    add_index :advisements, :enrollment_id
  end

  def self.down
    drop_table :advisements
  end
end

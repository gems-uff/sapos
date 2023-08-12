# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateProfessors < ActiveRecord::Migration[5.1]
  def self.up
    create_table :professors do |t|
      t.string :name
      t.string :cpf
      t.date :birthdate

      t.timestamps
    end
  end

  def self.down
    drop_table :professors
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddUserIdToProfessors < ActiveRecord::Migration[5.1]
  def self.up
    add_column :professors, :user_id, :integer, references: :users
    add_index :professors, :user_id
  end

  def self.down
    remove_index :professors, :user_id
    remove_column :professors, :user_id
  end
end

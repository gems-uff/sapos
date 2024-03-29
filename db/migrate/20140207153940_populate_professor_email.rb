# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PopulateProfessorEmail < ActiveRecord::Migration[5.1]
  def up
    add_index :users, :email
    add_index :professors, :email
  end

  def down
    remove_index :users, column: [:email]
    remove_index :professors, column: [:email]
  end
end

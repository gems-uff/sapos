# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RemoveHashedPasswordFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :hashed_password, :string
    remove_column :users, :salt, :string
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddUnconfirmedEmailToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :unconfirmed_email, :string
  end
end

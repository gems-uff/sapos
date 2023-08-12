# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddBirthCountryToStudent < ActiveRecord::Migration[5.1]
  def change
    add_column :students, :birth_country_id, :integer
    add_index :students, :birth_country_id
  end
end

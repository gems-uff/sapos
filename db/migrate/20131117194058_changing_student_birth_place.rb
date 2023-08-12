# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangingStudentBirthPlace < ActiveRecord::Migration[5.1]
  def change
    remove_column :students, :birthplace
    remove_column :students, :country_id
    rename_column :students, :state_id, :birth_state_id
    add_column :students, :birth_city_id, :integer
    add_index :students, :birth_city_id
  end
end

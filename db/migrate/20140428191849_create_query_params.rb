# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateQueryParams < ActiveRecord::Migration[5.1]
  def change
    create_table :query_params do |t|
      t.references :query
      t.string :name
      t.string :default_value
      t.string :value_type

      t.timestamps
    end
    #add_index :query_params, :query_id
  end
end

# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddDescriptionToQueries < ActiveRecord::Migration[5.1]
  def change
    add_column :queries, :description, :string, after: :sql
  end
end

# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RenameCustomVariablesNameToDescription < ActiveRecord::Migration
  def change
  	rename_column :custom_variables, :name, :description
  end
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ChangeCustomVariableValueType < ActiveRecord::Migration
  def up
  	change_column :custom_variables, :value, :text
  end

  def down
  	change_column :custom_variables, :value, :string
  end
end

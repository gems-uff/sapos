# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeCustomVariableValueType < ActiveRecord::Migration[5.1]
  def up
    change_column :custom_variables, :value, :text
  end

  def down
    change_column :custom_variables, :value, :string
  end
end

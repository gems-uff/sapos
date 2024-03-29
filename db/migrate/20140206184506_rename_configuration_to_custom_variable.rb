# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RenameConfigurationToCustomVariable < ActiveRecord::Migration[5.1]
  def up
    rename_table :configurations, :custom_variables
  end

  def down
    rename_table :custom_variables, :configurations
  end
end

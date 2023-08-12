# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeColumnTypeOfObjectInVersions < ActiveRecord::Migration[5.1]
  def change
    change_column :versions, :object, :text, limit: 16777215
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddModeToFormConditions < ActiveRecord::Migration[7.0]
  def change
    add_column :form_conditions, :mode, :string, default: "Condição"
  end
end

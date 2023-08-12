# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddActiveToPhases < ActiveRecord::Migration[6.0]
  def up
    change_table :phases do |t|
      t.boolean :active, default: true
    end
    Phase.where(active: nil).update_all(active: true)
  end

  def down
    change_table :phases do |t|
      t.remove :active
    end
  end
end

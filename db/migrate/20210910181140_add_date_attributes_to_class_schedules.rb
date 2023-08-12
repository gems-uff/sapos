# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddDateAttributesToClassSchedules < ActiveRecord::Migration[6.0]
  def change
    add_column :class_schedules, :enrollment_adjust, :datetime
    add_column :class_schedules, :enrollment_insert, :datetime
    add_column :class_schedules, :enrollment_remove, :datetime
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddOnDemandToCourseTypes < ActiveRecord::Migration[6.0]
  def change
    add_column :course_types, :on_demand, :boolean, null: false, default: false
  end
end

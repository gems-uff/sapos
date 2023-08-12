# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddObsScheduleToCourseClasses < ActiveRecord::Migration[6.0]
  def up
    change_table :course_classes do |t|
      t.string :obs_schedule
    end
  end

  def down
    change_table :course_classes do |t|
      t.remove :obs_schedule
    end
  end
end

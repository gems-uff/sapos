# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddSchedulableAndShowClassNameToCourseType < ActiveRecord::Migration[5.1]
  def change
    add_column :course_types, :schedulable, :boolean
    add_column :course_types, :show_class_name, :boolean
  end
end

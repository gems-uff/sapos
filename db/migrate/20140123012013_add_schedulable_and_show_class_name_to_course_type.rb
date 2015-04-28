# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddSchedulableAndShowClassNameToCourseType < ActiveRecord::Migration
  def change
    add_column :course_types, :schedulable, :boolean, default: true
    add_column :course_types, :show_class_name, :boolean, default: true
  end
end

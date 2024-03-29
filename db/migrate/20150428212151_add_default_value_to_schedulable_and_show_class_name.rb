# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddDefaultValueToSchedulableAndShowClassName < ActiveRecord::Migration[5.1]
  def self.up
    change_column_default :course_types, :schedulable, true
    change_column_default :course_types, :show_class_name, true
  end
  def self.down
    change_column_default :course_types, :schedulable, nil
    change_column_default :course_types, :show_class_name, nil
  end
end

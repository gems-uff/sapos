# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddThesisTitleToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :thesis_title, :string
  end
end

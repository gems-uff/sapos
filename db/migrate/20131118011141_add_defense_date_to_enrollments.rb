# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddDefenseDateToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :thesis_defense_date, :date
  end
end

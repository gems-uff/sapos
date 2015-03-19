# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddWorkloadToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :workload, :integer
  end
end

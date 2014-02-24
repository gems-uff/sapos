# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddFieldOfStudyToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :field_of_study, :string
  end
end

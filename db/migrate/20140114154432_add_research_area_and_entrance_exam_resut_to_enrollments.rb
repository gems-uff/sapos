# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddResearchAreaAndEntranceExamResutToEnrollments < ActiveRecord::Migration[5.1]
  def change
    add_column :enrollments, :research_area_id, :integer
    add_column :enrollments, :entrance_exam_result, :string
    remove_column :enrollments, :field_of_study
  end
end

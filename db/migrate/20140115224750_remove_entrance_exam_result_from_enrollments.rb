# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RemoveEntranceExamResultFromEnrollments < ActiveRecord::Migration
  def change
  	remove_column :enrollments, :entrance_exam_result
  end
end

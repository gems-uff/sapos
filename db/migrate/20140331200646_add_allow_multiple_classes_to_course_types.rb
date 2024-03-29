# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddAllowMultipleClassesToCourseTypes < ActiveRecord::Migration[5.1]
  def change
    add_column(
      :course_types, :allow_multiple_classes, :boolean,
      null: false, default: false, after: :has_score
    )
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module SubformColumnsHelper
  COLUMNS_WITHOUT_SCORE = [:grade, :grade_not_count_in_gpr].freeze

  def subform_column_omitted?(column, parent_record)
    return false unless COLUMNS_WITHOUT_SCORE.include?(column.name)
    return false unless parent_record.respond_to?(:course)

    parent_record.course.try(:course_type).try(:has_score) == false
  end
end

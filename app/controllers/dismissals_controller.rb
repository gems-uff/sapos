# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DismissalsController < ApplicationController
  authorize_resource

  active_scaffold :dismissal do |config|
    # Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    config.columns.add :enrollment, :level
    config.field_search.columns = [:enrollment, :level, :date, :dismissal_reason]
    config.columns[:enrollment].search_ui = :text
    config.columns[:enrollment].search_sql = "enrollments.enrollment_number"
    config.columns[:date].search_sql = "dismissals.date"
    config.columns[:level].search_sql = "enrollments.level"

    config.list.columns = [:enrollment, :dismissal_reason, :date, :obs]
    config.create.label = :create_dismissal_label
    config.columns[:dismissal_reason].form_ui = :select
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:date].options = { format: :monthyear }
    config.columns[:dismissal_reason].clear_link

    config.show.columns = [:enrollment, :level, :dismissal_reason, :obs]

    config.update.columns = [:enrollment, :date, :dismissal_reason, :obs]
    config.create.columns = [:enrollment, :date, :dismissal_reason, :obs]

    config.actions.exclude :deleted_records
  end

  def self.condition_for_level_column(column, value, like_pattern)
    unless value.blank?
      ["dismissals.id IN (
        SELECT dismissals.id
        FROM enrollments
        JOIN dismissals ON enrollments.id = dismissals.enrollment_id
      WHERE  enrollments.level_id = ?
    )", value]
    end
  end

  def self.condition_for_date_column(column, value, like_pattern)
    unless value.blank? || value["year"].to_i == 0
      date = Date.new(value["year"].to_i, value["month"].to_i, value["day"].to_i)
      next_year = date.next_year
      ["dismissals.id IN (
        SELECT dismissals.id
        FROM enrollments
        JOIN dismissals ON enrollments.id = dismissals.enrollment_id
        WHERE dismissals.date >= ? AND dismissals.date < ?
      )", date, next_year]
    end
  end
end

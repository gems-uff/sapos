# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class EnrollmentHoldsController < ApplicationController
  authorize_resource
  active_scaffold :"enrollment_hold" do |config|
    config.create.label = :create_enrollment_hold_label
    config.actions.swap :search, :field_search
    config.field_search.columns = [:enrollment, :active]
    config.columns = [
      :enrollment, :year, :semester, :number_of_semesters
    ]
    config.columns[:enrollment].search_ui = :text
    config.columns[:enrollment].search_sql = "enrollments.enrollment_number"

    config.columns.add :active
    config.list.columns.exclude :active
    config.show.columns.exclude :active
    config.update.columns.exclude :active
    config.create.columns.exclude :active
    config.columns[:active].search_sql = ""
    config.columns[:active].search_ui = :select
    config.columns[:active].options = {
      options: [
        [I18n.t("active_scaffold.true"), "1"],
        [I18n.t("active_scaffold.false"), "0"]
      ],
      include_blank: true,
      default: nil,
    }

    config.columns[:enrollment].form_ui = :record_select
    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
      options: YearSemester::SEMESTERS,
      include_blank: true,
      default: nil,
    }
    config.columns[:year].options = {
      options: YearSemester.selectable_years,
      include_blank: true,
      default: nil,
    }

    config.actions.exclude :deleted_records
  end

  def self.condition_for_active_column(column, value, like_pattern)
    return "" if value.blank?
    ids = EnrollmentHold.currently_active_ids
    case value
    when "1"
      return "1 = 2" if ids.blank?
      "enrollment_holds.id IN (#{ids.join(',')})"
    when "0"
      return "" if ids.blank?
      "enrollment_holds.id NOT IN (#{ids.join(',')})"
    else
      ""
    end
  end
end

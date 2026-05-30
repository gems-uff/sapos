# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ClassSchedulesController < ApplicationController
  include SharedPdfConcern
  authorize_resource
  helper :course_classes

  active_scaffold :"class_schedule" do |config|
    # Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    config.field_search.columns = [:year, :semester]
    columns = [
      :year, :semester, :enrollment_start, :enrollment_end, :period_start,
      :enrollment_insert, :enrollment_remove, :period_end, :grades_deadline
    ]
    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns
    config.create.label = :create_class_schedule_label

    config.action_links.add "class_schedule_pdf",
      label: "<i title='#{
        I18n.t("pdf_content.class_schedule.class_schedule_pdf.link")
      }' class='fa fa-book'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }

    config.actions.exclude :deleted_records

    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
      options: YearSemester::SEMESTERS,
      include_blank: true,
      default: nil
    }
    config.columns[:year].options = {
      options: YearSemester.selectable_years,
      include_blank: true,
      default: nil
    }
    config.columns[:enrollment_start].form_ui = :datetime_picker
    config.columns[:enrollment_start].options = { format: :picker }
    config.columns[:enrollment_end].form_ui = :datetime_picker
    config.columns[:enrollment_end].options = { format: :picker }
    config.columns[:period_start].form_ui = :datetime_picker
    config.columns[:period_start].options = { format: :picker }
    config.columns[:enrollment_insert].form_ui = :datetime_picker
    config.columns[:enrollment_insert].options = { format: :picker }
    config.columns[:enrollment_remove].form_ui = :datetime_picker
    config.columns[:enrollment_remove].options = { format: :picker }
    config.columns[:period_end].form_ui = :datetime_picker
    config.columns[:period_end].options = { format: :picker }
    config.columns[:grades_deadline].form_ui = :datetime_picker
    config.columns[:grades_deadline].options = { format: :picker }
  end

  def class_schedule_pdf
    schedule = ClassSchedule.find(params[:id])

    year = schedule.year
    semester = schedule.semester

    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.class_schedule.class_schedule_pdf.title")
        send_data render_class_schedules_class_schedule_pdf(year, semester),
          filename: "#{title} (#{year}_#{semester}).pdf",
          type: "application/pdf"
      end
    end
  end
end

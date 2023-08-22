# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ClassSchedulesController < ApplicationController
  authorize_resource
  helper :course_classes

  active_scaffold :"class_schedule" do |config|
    # Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    config.field_search.columns = [:year, :semester]
    columns = [
      :year, :semester, :enrollment_start, :enrollment_end, :enrollment_adjust,
      :enrollment_insert, :enrollment_remove
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
    config.columns[:enrollment_adjust].form_ui = :datetime_picker
    config.columns[:enrollment_adjust].options = { format: :picker }
    config.columns[:enrollment_insert].form_ui = :datetime_picker
    config.columns[:enrollment_insert].options = { format: :picker }
    config.columns[:enrollment_remove].form_ui = :datetime_picker
    config.columns[:enrollment_remove].options = { format: :picker }
  end

  def class_schedule_pdf
    schedule = ClassSchedule.find(params[:id])
    if schedule.nil?
      flash[:error] = I18n.t(
        "pdf_content.class_schedule.class_schedule_pdf.year_semester_not_found"
      )
      return redirect_to action: :index
    end

    @year = schedule.year
    @semester = schedule.semester
    @course_classes = CourseClass.where(year: @year, semester: @semester)
    @on_demand = Course.joins(:course_type).where(
      course_types: { on_demand: true }
    )

    respond_to do |format|
      format.pdf do
        stream = render_to_string
        filename = "#{I18n.t(
          "pdf_content.class_schedule.class_schedule_pdf.title"
        )} (#{@year}_#{@semester}).pdf"
        send_data(stream, filename: filename, type: "application/pdf")
      end
    end
  end
end

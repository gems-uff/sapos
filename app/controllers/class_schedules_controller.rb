class ClassSchedulesController < ApplicationController
  authorize_resource

  active_scaffold :"class_schedule" do |config|
    config.list.columns = [:year, :semester, :enrollment_start, :enrollment_end]
    config.create.columns = [:year, :semester, :enrollment_start, :enrollment_end]
    config.update.columns = [:year, :semester, :enrollment_start, :enrollment_end]
    config.create.label = :create_class_schedule_label
    config.update.label = :update_class_schedule_label

    config.actions.exclude :deleted_records

    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
      :options => CourseClass::SEMESTERS,
      :include_blank => true,
      :default => nil
    }
    config.columns[:year].options = {
      :options => CourseClass.selectable_years,
      :include_blank => true,
      :default => nil
    }
  end
end

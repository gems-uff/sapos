# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AdmissionDataController < ApplicationController
  include Panel::AdmissionDataHelper

  authorize_resource class: false, instance_name: :panel

  active_scaffold :"admissions/admission_process" do |config|
    config.label = I18n.t("panel.admission_data.title")
    config.actions = [:list, :show, :field_search]

    config.columns.add :admission_applications_count
    config.columns.add :year_semester
    config.columns.add :is_open?

    config.list.columns = [:name, :year_semester, :admission_applications_count, :is_open?]
    config.show.columns = [:name, :year_semester, :start_date, :end_date, :admission_applications_count, :is_open?]
    config.list.sorting = { year: :desc, semester: :desc }

    config.field_search.columns = [:name, :year, :semester]
    config.columns[:name].search_ui = :text

    config.columns[:name].label = I18n.t("panel.admission_data.process_name")
    config.columns[:year_semester].label = I18n.t("panel.admission_data.year_semester")
    config.columns[:admission_applications_count].label = I18n.t("panel.admission_data.applications_count")
    config.columns[:is_open?].label = I18n.t("panel.admission_data.status")

    config.action_links.add :export,
      label: "<i title='#{I18n.t("panel.admission_data.export")}' class='fa fa-upload'></i>".html_safe,
      type: :member

    config.action_links.add :import,
      label: "<i title='#{I18n.t("panel.admission_data.import")}' class='fa fa-download'></i>".html_safe,
      type: :collection

    config.action_links.add :purge,
      label: "<i title='#{I18n.t("panel.admission_data.delete")}' class='fa fa-trash-o'></i>".html_safe,
      type: :member
  end

  def export
    flash[:info] = I18n.t("panel.admission_data.coming_soon")
    redirect_to panel_selection_processes_path
  end

  def import
    flash[:info] = I18n.t("panel.admission_data.coming_soon")
    redirect_to panel_selection_processes_path
  end

  def purge
    flash[:info] = I18n.t("panel.admission_data.coming_soon")
    redirect_to panel_selection_processes_path
  end
end

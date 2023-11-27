# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcessesController < ApplicationController
  authorize_resource
  include ApplicationHelper
  include PdfHelper

  active_scaffold "Admissions::AdmissionProcess" do |config|
    config.list.sorting = { end_date: "DESC" }
    config.create.label = :create_admission_process_label

    config.columns.add :admission_applications_count
    config.columns.add :year_semester

    form_columns = [
      :name, :simple_url, :year, :semester, :start_date, :end_date,
      :form_template, :letter_template, :min_letters, :max_letters,
      :allow_multiple_applications, :require_session, :visible, :phases
    ]
    config.create.columns = form_columns
    config.update.columns = form_columns
    config.list.columns = [
      :year, :semester, :name, :simple_id,
      :start_date, :end_date,
      :admission_applications_count, :is_open?
    ]
    config.show.columns = [
      :name, :year_semester, :simple_id, :start_date, :end_date,
      :form_template, :letter_template, :min_letters, :max_letters,
      :allow_multiple_applications, :require_session, :visible,
      :is_open?, :admission_applications_count,
      :admission_applications
    ]

    config.actions << :duplicate
    config.duplicate.link.label = "
      <i title='#{I18n.t("active_scaffold.duplicate")}' class='fa fa-copy'></i>
    ".html_safe
    config.duplicate.link.method = :get
    config.duplicate.link.position = :after
    config.action_links.add "short_pdf",
      label: "<i title='#{
        I18n.t "pdf_content.admissions/admission_process.short_pdf.filename"
      }' class='fa fa-file-text-o'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }
    config.action_links.add "complete_pdf",
      label: "<i title='#{
        I18n.t "pdf_content.admissions/admission_process.complete_pdf.filename"
      }' class='fa fa-book'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }
    config.action_links.add "complete_xls",
      label: "<i title='#{
        I18n.t "xlsx_content.admissions/admission_process.complete_xls.filename"
      }' class='fa fa-table'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :xlsx }

    config.columns[:form_template].form_ui = :record_select
    config.columns[:form_template].options[:params] = {
      template_type: Admissions::FormTemplate::ADMISSION_FORM
    }
    config.columns[:letter_template].form_ui = :record_select
    config.columns[:letter_template].options[:params] = {
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    }

    config.actions.exclude :deleted_records
  end

  record_select(
    per_page: 10, search_on: [:name, :year, :semester],
    order_by: "year desc, semester desc, name", full_text_search: true,
    model: "Admissions::AdmissionProcess"
  )

  def short_pdf
    get_admission_process_pdf("short_pdf")
  end

  def complete_pdf
    get_admission_process_pdf("complete_pdf")
  end

  def complete_xls
    @admission_process = Admissions::AdmissionProcess.find(params[:id])
    respond_to do |format|
      format.xlsx
    end
  end

  private
    def get_admission_process_pdf(type)
      @admission_process = Admissions::AdmissionProcess.find(params[:id])
      respond_to do |format|
        format.pdf do
          filename = I18n.t(
            "pdf_content.admissions/admission_process.#{type}.filename"
          )
          send_data render_to_string,
            filename: "#{filename} - #{@admission_process.title}.pdf",
            type: "application/pdf"
        end
      end
    end
end

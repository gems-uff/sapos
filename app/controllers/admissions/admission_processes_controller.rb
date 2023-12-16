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
      :name, :simple_url, :year, :semester, :start_date, :end_date, :edit_date,
      :form_template, :letter_template, :min_letters, :max_letters,
      :allow_multiple_applications, :require_session, :visible,
      :staff_can_edit, :staff_can_undo, :phases, :rankings
    ]
    config.create.columns = form_columns
    config.update.columns = form_columns
    config.list.columns = [
      :year, :semester, :name, :simple_id,
      :start_date, :end_date, :edit_date,
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
    config.action_links.add "phase_status",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_process.phase_status.title"
      }' class='fa fa-play'></i>".html_safe,
      type: :member
    config.action_links.add "rankings",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_process.rankings.title"
      }' class='fa fa-sort'></i>".html_safe,
      type: :member
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
    config.columns[:phases].show_blank_record = false
    config.columns[:rankings].show_blank_record = false

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

  def phase_status
    @admission_process = Admissions::AdmissionProcess.find(params[:id])
  end

  def consolidate_phase
    i18n_prefix = "active_scaffold.admissions/admission_process.consolidate_phase"
    @admission_process = Admissions::AdmissionProcess.find(params[:id])
    @show_page = params[:show_summary]
    phase_id = params[:consolidate_phase_id].to_i
    phase_id = nil if phase_id == 0
    phases = [nil] + @admission_process.phases.order(:order).map do |p|
      p.admission_phase.id
    end
    index = phases.find_index(phase_id)
    @phase = phase_id.nil? ? nil : Admissions::AdmissionPhase.find(phases[index])
    @phase_name = @phase.nil? ? "Candidatura" : @phase.name
    @message = I18n.t("#{i18n_prefix}.title", phase: @phase_name)
    candidates = @admission_process.admission_applications
      .where(admission_phase_id: phase_id)
      .ready_for_consolidation(phase_id)
    @approved = []
    @reproved = []
    @errors = []
    @missing_committee = []

    candidates.each do |candidate|
      case candidate.consolidate_phase!(@phase)
      when Admissions::AdmissionApplication::APPROVED
        @approved << candidate
      when Admissions::AdmissionApplication::REPROVED
        @reproved << candidate
      else
        @errors << candidate
      end
    end

    if index < phases.size - 1
      next_phase_id = phases[index + 1]
      next_phase = Admissions::AdmissionPhase.find(next_phase_id)
      # Query again insted of using the approved variable to allow the
      # posterior addition of phases
      change_phase_candidates = @admission_process.admission_applications
        .where(admission_phase_id: @phase.try(:id))
        .where(status: Admissions::AdmissionApplication::APPROVED)
      change_phase_candidates.each do |candidate|
        if !next_phase.create_pendencies_for_candidate(
          candidate, should_raise: Admissions::FormCondition::RAISE_COMMITTEE
        )
          @missing_committee << candidate
        end
        candidate.update!(
          admission_phase_id: next_phase_id,
          status: nil,
          status_message: nil
        )
        @errors << candidate
      rescue => err
        @approved.delete(candidate)
        candidate.update!(
          status: Admissions::AdmissionApplication::ERROR,
          status_message: err
        )
      end
    end

    if !@show_page
      if @errors.present?
        @message += ". #{I18n.t("#{i18n_prefix}.errors", count: @errors.count)}"
      end
      if @missing_committee.present?
        @message += ". #{I18n.t("#{i18n_prefix}.missing_committee", count: @missing_committee.count)}"
      end
      if @reproved.present?
        @message += ". #{I18n.t("#{i18n_prefix}.reproved", count: @reproved.count)}"
      end
      if @approved.present?
        @message += ". #{I18n.t("#{i18n_prefix}.approved", count: @approved.count)}"
      end
    end


    params.each_key do |key|
      if !["authenticity_token", "controller", "action"].include? key
        params.delete key
      end
    end
    do_refresh_list
    respond_to_action(:consolidate_phase)
  end

  def rankings
    @admission_process = Admissions::AdmissionProcess.find(params[:id])
  end

  def calculate_ranking
    @admission_process = Admissions::AdmissionProcess.find(params[:id])
    begin
      @errors = nil
      @ranking = @admission_process.rankings.where(id: params[:admission_process_ranking_id]).first
      @candidates = @ranking.generate_ranking
    rescue => exception
      @errors = exception
    end

    params.each_key do |key|
      if !["authenticity_token", "controller", "action"].include? key
        params.delete key
      end
    end
    respond_to_action(:calculate_ranking)
  end

  protected
    def consolidate_phase_respond_on_iframe
      flash[:info] = @message
      responds_to_parent do
        render action: "on_consolidate_phase", formats: [:js], layout: false
      end
    end

    def consolidate_phase_respond_to_html
      flash[:info] = @message
      return_to_main
    end

    def consolidate_phase_respond_to_js
      flash.now[:info] = @message
      do_refresh_list
      @popstate = true
      render action: "on_consolidate_phase", formats: [:js]
    end

    def calculate_ranking_respond_on_iframe
      flash[:error] = @errors
      responds_to_parent do
        render action: "on_calculate_ranking", formats: [:js], layout: false
      end
    end

    def calculate_ranking_respond_to_html
      flash[:error] = @errors
      return_to_main
    end

    def calculate_ranking_respond_to_js
      flash.now[:error] = @errors
      do_refresh_list
      @popstate = true
      render action: "on_calculate_ranking", formats: [:js]
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

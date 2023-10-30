# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::ApplyController < Admissions::ProcessBaseController
  before_action only: [:new, :create] do
    find_admission_process(:admission_id)
  end
  before_action :find_admission_application, only: [:show, :edit, :update]
  before_action :check_if_process_is_open, only: [:new, :create, :edit, :update]
  before_action :prepare_new_admission_application, only: [:new, :create]

  active_scaffold :active_scaffold_workaround # Load helpers

  def show
    prepare_admission_application_fields
  end

  def new
    edit(creating: true)
  end

  def create
    update(creating: true)
  end

  def edit(creating: false)
    prepare_edit_update_application(creating: creating)
    prepare_admission_application_fields
    render :edit
  end

  def update(creating: false)
    prepare_edit_update_application(creating: creating)
    @admission_application.assign_attributes(admission_application_params)
    @admission_application.filled_form.sync_fields_after(@admission_application)
    was_filled = @admission_application.filled_form.is_filled
    @admission_application.filled_form.is_filled = true
    if @admission_application.save
      emails = [EmailTemplate.load_template(
        was_filled ?
          "admissions/apply:edit_email_to_student" :
          "admissions/apply:email_to_student"
      ).prepare_message({
        record: @admission_application,
        admission_process: @admission_process,
        admission_apply_url: admission_apply_url(
          admission_id: @admission_process.simple_id,
          id: @admission_application.token
        )
      })]
      @admission_application.letter_requests.each do |letter_request|
        if letter_request.sent_email != letter_request.email
          emails << EmailTemplate.load_template(
            "admissions/apply:request_letter"
          ).prepare_message({
            record: @admission_application,
            admission_process: @admission_process,
            letter_request: letter_request,
            fill_letter_url: admission_letter_url(
              admission_id: @admission_process.simple_id,
              id: letter_request.access_token
            )
          })
          letter_request.update(sent_email: letter_request.email)
        end
      end
      Notifier.send_emails(notifications: emails)
      notice = was_filled ?
        I18n.t("admissions.apply.update.edit_notice") :
        I18n.t("admissions.apply.update.new_notice")

      if @admission_application.admission_process.require_session
        add_token_to_session(@admission_application.token)
      end
      redirect_to admission_apply_path(
        admission_id: @admission_process.simple_id,
        id: @admission_application.token
      ), notice: notice
    else
      @admission_application.filled_form.is_filled = was_filled
      prepare_admission_application_fields
      render :edit
    end
  end

  private
    def prepare_new_admission_application
      if @admission_process.require_session
        return redirect_to admissions_path,
          alert: I18n.t("errors.admissions.invalid_application")
      end
      @admission_application = Admissions::AdmissionApplication.new(
        admission_process: @admission_process,
        filled_form: Admissions::FilledForm.new(
          is_filled: false,
          form_template: @admission_process.form_template
        )
      )
      @show_name = @admission_process.form_template.fields
        .where(sync: Admissions::FormField::SYNC_NAME).first.blank?
      @show_email = @admission_process.form_template.fields
        .where(sync: Admissions::FormField::SYNC_EMAIL).first.blank?
      @submission_url = admission_apply_index_path(
        admission_id: @admission_process.simple_id,
      )
      @submission_method = :post
    end

    def prepare_edit_update_application(creating: false)
      if !creating
        @show_name = false
        @show_email = false
        @submission_url = admission_apply_path(
          admission_id: @admission_process.simple_id,
          id: @admission_application.token
        )
        @submission_method = :put
      end
    end

    def find_admission_application
      @admission_application = Admissions::AdmissionApplication
        .joins(:admission_process)
        .where('
          `admission_processes`.`simple_url` = :process_id OR
          `admission_processes`.`id` = :process_id',
          process_id: params[:admission_id]
        )
        .where(token: params[:id]).first
      if @admission_application.blank?
        return redirect_to admissions_path,
          alert: I18n.t("errors.admissions.invalid_application")
      end
      @admission_process = @admission_application.admission_process
      if @admission_process.require_session
        if !(session[:admission_tokens] || []).include?(@admission_application.token)
          redirect_to admissions_path,
            alert: I18n.t("errors.admissions.unauthorized_application",
                          token: @admission_application.token)
        end
      end
    end

    def check_if_process_is_open
      if !@admission_process.is_open?
        redirect_to admission_apply_path(
          admission_id: @admission_process.simple_id,
          id: @admission_application.token
        ), alert: I18n.t("errors.admissions.closed_process")
      end
    end

    def prepare_admission_application_fields
      filled_form = @admission_application.filled_form
      filled_form.prepare_missing_fields
      @admission_application.prepare_missing_letters
      filled_form.sync_fields_before(@admission_application)
    end

    def admission_application_params
      params.require(:record).permit(
        :name, :email,
        filled_form_attributes:
          Admissions::FilledFormsController.filled_form_params_definition,
        letter_requests_attributes: [
          :id, :email, :name, :telephone,
          :_destroy
        ]
      )
    end
end

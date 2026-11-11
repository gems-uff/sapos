# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::ApplyController < Admissions::ProcessBaseController
  before_action only: [:new, :create] do
    find_admission_process(:admission_id)
  end
  before_action :find_admission_application, only: [:show, :edit, :update]
  before_action :check_if_process_is_open_to_new, only: [:new, :create]
  before_action :check_if_process_is_open_to_edit, only: [:edit, :update]
  before_action :prepare_new_admission_application, only: [:new, :create]
  before_action :check_submitted_record, only: [:create, :update]

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
    was_filled = @admission_application.filled_form.is_filled
    previous_token = @admission_application.token
    @admission_application.assign_form(
      submitted_params(creating: creating),
      has_letter_forms: false,
      has_phases: @admission_application.admission_phase.present?,
      has_rankings: true,
      can_edit_override: false,
      check_candidate_permission: true,
      committee_permission_user: nil
    )
    if !was_filled
      @admission_application.submission_time = Time.current
    end
    @admission_application.filled_form.is_filled = true
    # O codigo de identificacao so viaja por e-mail, para o endereco da
    # inscricao: quem o apresenta leu a caixa daquele endereco. Quando o
    # candidato muda o endereco -- pelo campo do formulario sincronizado com o
    # e-mail --, a troca fica pendente (assign_form liga
    # email_change_needs_confirmation): o e-mail e o codigo continuam os de
    # antes ate o endereco novo confirmar pelo link que segue abaixo (#752).
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
      email_change = email_change_message
      emails << email_change if email_change
      Notifier.send_emails(notifications: emails)
      # Inscricao que nasce aqui (processo sem sessao): o navegador nao recebe
      # o codigo, so o aviso de para onde ele foi.
      if creating
        session[:admission_tokens]&.delete(previous_token)
        return redirect_to admissions_path, token_delivery_flash(
          "admissions.apply.update.new_token_sent", @admission_application.email, emails.first(1)
        )
      end
      if email_change
        # O aviso de para onde o link foi; quando a mensagem nao sai, ninguem
        # tem como confirmar, e o pedido nao fica pendente.
        flash_message = token_delivery_flash(
          "admissions.apply.update.email_change_requested",
          @admission_application.pending_email, [email_change]
        )
        @admission_application.cancel_email_change if flash_message.key?(:alert)
      else
        flash_message = { notice: was_filled ?
          I18n.t("admissions.apply.update.edit_notice") :
          I18n.t("admissions.apply.update.new_notice") }
      end

      if @admission_application.admission_process.require_session
        add_token_to_session(@admission_application.token)
      end
      redirect_to admission_apply_path(
        admission_id: @admission_process.simple_id,
        id: @admission_application.token
      ), flash_message
    else
      # Formulário que a validação do cliente deixou passar e o servidor
      # recusou (issue #605). O e-mail leva o motivo técnico, atributo e tipo
      # de cada erro; o que o candidato preencheu fica no log do servidor, que
      # já registra os parâmetros da requisição, junto com as mensagens.
      Rails.logger.warn(
        "Inscrição recusada no servidor: " +
        @admission_application.errors.full_messages.join("; ")
      )
      ExceptionNotifier.notify_exception(
        Exception.new("Validação javascript de seleção falhou e form com erro chegou no servidor"),
        env: request.env,
        data: {
          errors: @admission_application.errors.map do |error|
            "#{error.attribute}: #{error.type}"
          end
        }
      )
      if !was_filled
        @admission_application.submission_time = nil
      end
      @admission_application.filled_form.is_filled = was_filled
      prepare_admission_application_fields
      @show_reupload_files_notice = @admission_application
        .filled_form.form_template.has_file_fields?
      if @show_reupload_files_notice
        @admission_application.filled_form.erase_non_filled_file_fields
      end
      render :edit
    end
  end

  private
    # A mensagem com o link de validacao, quando este envio pediu a troca do
    # e-mail. Vai para o endereco novo, e nao leva o codigo da inscricao.
    def email_change_message
      token = @admission_application.email_change_token
      return nil if token.blank?

      EmailTemplate.load_template(
        "admissions/apply:confirm_email_change"
      ).prepare_message({
        email: @admission_application.pending_email,
        identifier: @admission_application.identifier,
        validity_hours: Admissions::AdmissionApplication::EMAIL_CHANGE_VALIDITY.in_hours.to_i,
        admission_process: @admission_process,
        confirm_email_change_url: admission_email_change_url(id: token)
      })
    end

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

    # Submissão que chega sem o formulário no parâmetro record — upload
    # interrompido, duplo clique em "Modificar inscrição", envio que não veio
    # da tela. Sem isso, o params.require(:record).permit estoura e o candidato
    # recebe a página crua de erro do Rails, sem entender o que houve nem o
    # que fazer.
    def check_submitted_record
      return if submitted_record?

      target = if @admission_application&.token.present?
        admission_apply_path(
          admission_id: @admission_process.simple_id,
          id: @admission_application.token
        )
      else
        new_admission_apply_path(admission_id: @admission_process.simple_id)
      end
      redirect_to target, alert: I18n.t("errors.admissions.empty_submission")
    end

    def prepare_edit_update_application(creating: false)
      if !creating
        @show_name = false
        @show_email = false
        @show_reupload_files_notice = false
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

    def check_if_process_is_open_to_new
      if !@admission_process.is_open?
        redirect_to admission_apply_path(
          admission_id: @admission_process.simple_id,
          id: @admission_application.token
        ), alert: I18n.t("errors.admissions.closed_process")
      end
    end

    def check_if_process_is_open_to_edit
      if @admission_application.candidate_can_edit.blank?
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

    # Nome e e-mail so sao campos da tela quando a inscricao nasce no envio do
    # formulario (processo sem sessao). Na edicao a tela nao os oferece: eles
    # so mudam pelo campo do formulario sincronizado com cada um.
    #
    # O formulario principal, quando a tela o oferece ao candidato, e sempre
    # submetido (submitted_form).
    def submitted_params(creating:)
      submitted = admission_application_params
      submitted = submitted.except(:name, :email) unless creating
      if @admission_application.can_edit_main_form?(check_candidate_permission: true)
        submitted[:filled_form_attributes] = submitted_form(submitted[:filled_form_attributes])
      end
      submitted
    end

    def admission_application_params
      params.require(:record).permit(
        :name, :email,
        filled_form_attributes:
          Admissions::FilledFormsController.filled_form_params_definition,
        letter_requests_attributes: [
          :id, :email, :name, :telephone,
          :_destroy
        ],
        results_attributes: [
          :id, :mode, :admission_phase_id,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ]
      )
    end
end

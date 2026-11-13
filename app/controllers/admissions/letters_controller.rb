# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::LettersController < Admissions::ProcessBaseController
  before_action :find_letter_request, only: [:show, :update]
  before_action :check_if_process_is_open, only: [:show, :update]
  before_action :check_submitted_record, only: [:update]

  active_scaffold :active_scaffold_workaround # Load helpers

  def show
    prepare_letter_request_fields
  end

  def update
    @letter_request.assign_attributes(letter_request_params)
    # o campo que o envio nao trouxe e conferido como campo sem resposta
    @letter_request.filled_form.prepare_missing_fields
    @letter_request.filled_form.sync_fields_after(@letter_request)
    was_filled = @letter_request.filled_form.is_filled
    @letter_request.filled_form.is_filled = true
    if @letter_request.save
      redirect_to admissions_path,
        notice: I18n.t("admissions.letters.update.success")
    else
      @letter_request.filled_form.is_filled = was_filled
      prepare_letter_request_fields
      render :show
    end
  end

  private
    def find_letter_request
      @letter_request = Admissions::LetterRequest
        .joins(admission_application: :admission_process)
        .where('
          `admission_processes`.`simple_url` = :process_id OR
          `admission_processes`.`id` = :process_id',
          process_id: params[:admission_id]
        )
        .where(access_token: params[:id]).first
      if @letter_request.blank?
        return redirect_to admissions_path,
          alert: I18n.t("errors.admissions.invalid_letter")
      end
      @admission_application = @letter_request.admission_application
      @admission_process = @admission_application.admission_process
    end

    def check_if_process_is_open
      if !@admission_process.is_open? && !@admission_process.is_open_to_edit?
        redirect_to admissions_path,
          alert: I18n.t("errors.admissions.closed_process")
      end
    end

    # O mesmo de ApplyController#check_submitted_record: o envio que nao traz
    # o formulario devolve o recomendador a carta, com um aviso.
    def check_submitted_record
      return if submitted_record?

      redirect_to admission_letter_path(
        admission_id: @admission_process.simple_id,
        id: @letter_request.access_token
      ), alert: I18n.t("errors.admissions.empty_submission")
    end

    def prepare_letter_request_fields
      filled_form = @letter_request.filled_form
      filled_form.prepare_missing_fields
      filled_form.sync_fields_before(@letter_request)
    end

    # O recomendador preenche os campos da carta. O pedido, o formulario
    # preenchido e o template sao os do servidor, nunca os que vem nos
    # parametros -- a mesma regra de AdmissionApplication#assign_form. E a
    # carta e sempre submetida (submitted_form).
    def letter_request_params
      permitted = params.require(:record).permit(
        :email, :name, :telephone,
        filled_form_attributes:
          Admissions::FilledFormsController.filled_form_params_definition,
      )
      attributes = submitted_form(permitted[:filled_form_attributes])
        .except(:form_template_id, :is_filled, :id).to_h.with_indifferent_access
      if attributes.key?(:fields_attributes)
        attributes[:fields_attributes] =
          Admissions::FilledForm.submitted_fields(attributes[:fields_attributes])
      end
      filled_form = @letter_request.filled_form
      attributes[:id] = filled_form.id if filled_form&.persisted?
      permitted.to_h.merge(filled_form_attributes: attributes)
    end
end

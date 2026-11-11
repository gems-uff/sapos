# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::ProcessBaseController < ApplicationController
  skip_authorization_check
  skip_authorize_resource
  skip_before_action :authenticate_user!
  skip_before_action :prepare_background
  before_action :set_show_background

  protected
    def find_admission_process(param_id)
      @admission_process =
        Admissions::AdmissionProcess.open.find_by(simple_url: params[param_id]) ||
        Admissions::AdmissionProcess.open.find_by(id: params[param_id])
      if @admission_process.blank?
        redirect_to admissions_path,
          alert: I18n.t("errors.admissions.invalid_process")
      end
    end

    # O aviso de para onde o codigo foi. Quando a mensagem que o leva nao sai
    # (variavel redirect_email vazia, envio desligado no ambiente, ou modelo
    # de e-mail desabilitado na instalacao), a tela diz isso em vez de afirmar
    # um envio que nao houve: a inscricao existe, e quem gerencia o processo ve
    # o codigo e pode passa-lo.
    def token_delivery_flash(key, email, messages, **interpolation)
      if Notifier.sending? && messages.any? { |message| !message[:skip_message] }
        { notice: I18n.t(key, email: email, **interpolation) }
      else
        { alert: I18n.t("#{key}_without_email", **interpolation) }
      end
    end

    # O formulario da tela chega em params[:record] como um conjunto de campos.
    # O que chega de outro jeito -- ausente, vazio, texto solto, lista -- nao
    # veio da tela, e nao segue para o params.require(:record).permit.
    def submitted_record?
      params[:record].is_a?(ActionController::Parameters) && params[:record].present?
    end

    # O formulario que a tela publica oferece e sempre submetido: so a tela
    # interna, com a edicao total, desliga a submissao de um formulario
    # (enable_submission). O que chega sem os campos do formulario, ou com eles
    # em formato que a tela nao manda, e o formulario sem resposta, e e
    # conferido como tal -- em vez de ser gravado sem conferencia.
    def submitted_form(attributes)
      unless attributes.is_a?(ActionController::Parameters)
        attributes = ActionController::Parameters.new.permit!
      end
      attributes.merge(enable_submission: "1")
    end

    def add_token_to_session(token)
      session[:admission_tokens] = Set.new if session[:admission_tokens].blank?
      session[:admission_tokens].add(token)
    end

  private
    def set_show_background
      @show_background = true
    end
end

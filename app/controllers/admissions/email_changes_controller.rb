# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A confirmacao da troca de e-mail que o candidato pediu no formulario (#752).
# O link vai para o endereco novo: quem o abre leu aquela caixa. Abrir o link
# so mostra a pagina; a troca acontece no botao (PUT), porque filtro de e-mail
# visita link sozinho.
class Admissions::EmailChangesController < Admissions::ProcessBaseController
  before_action :find_admission_application

  def show
  end

  def update
    previous_token = @admission_application.token
    new_email = @admission_application.pending_email
    unless @admission_application.confirm_email_change
      # O endereco deixou de servir depois do pedido (outra inscricao do
      # processo passou a usa-lo): o pedido acaba, e a inscricao fica como esta.
      reasons = @admission_application.errors.full_messages.join("; ")
      @admission_application.reload.cancel_email_change
      return redirect_to admissions_path,
        alert: I18n.t("admissions.email_changes.update.refused", reasons: reasons)
    end

    # O codigo mudou com o endereco, e so viaja por e-mail: o navegador recebe
    # o aviso de para onde ele foi.
    session[:admission_tokens]&.delete(previous_token)
    messages = [EmailTemplate.load_template(
      "admissions/apply:edit_email_to_student"
    ).prepare_message({
      record: @admission_application,
      admission_process: @admission_process,
      admission_apply_url: admission_apply_url(
        admission_id: @admission_process.simple_id,
        id: @admission_application.token
      )
    })]
    Notifier.send_emails(notifications: messages)
    redirect_to admissions_path, token_delivery_flash(
      "admissions.email_changes.update.success", new_email, messages
    )
  end

  private
    def find_admission_application
      @admission_application =
        Admissions::AdmissionApplication.find_by_email_change_token(params[:id])
      if @admission_application.blank?
        return redirect_to admissions_path,
          alert: I18n.t("errors.admissions.invalid_email_change")
      end
      @admission_process = @admission_application.admission_process
    end
end

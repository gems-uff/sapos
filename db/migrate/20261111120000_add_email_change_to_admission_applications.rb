# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A troca de e-mail pedida pelo candidato so vale depois de confirmada pelo
# endereco novo (#752). Ate la a candidatura guarda o endereco pedido
# (pending_email), o resumo do codigo do link de validacao
# (email_change_digest -- o codigo em si so existe na mensagem) e quando o
# link foi mandado (email_change_sent_at), que e de onde se conta a validade.
class AddEmailChangeToAdmissionApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :admission_applications, :pending_email, :string
    add_column :admission_applications, :email_change_digest, :string
    add_column :admission_applications, :email_change_sent_at, :datetime
    add_index :admission_applications, :email_change_digest
  end
end

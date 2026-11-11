# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::LetterRequestsHelper
  # O codigo de acesso e a credencial do recomendador: abre a pagina publica da
  # carta, que aceita alteracao. So o ve quem gerencia o processo, como link,
  # para preencher a carta em nome do recomendador. O membro da comissao le a
  # carta pela tela da candidatura e fica sem o codigo.
  def access_token_column(record, column)
    return unless can?(:manage, record)

    link_to record.access_token, admission_letter_url(
      admission_id: record.admission_application.admission_process.simple_id,
      id: record.access_token
    )
  end
end

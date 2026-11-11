# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::LetterRequestsHelper
  # O codigo de acesso e a credencial do recomendador: abre a pagina publica da
  # carta, que aceita alteracao. Quem gerencia a carta o ve como link, para
  # preenche-la em nome do recomendador; quem gerencia o processo seletivo sem
  # gerenciar a carta (a secretaria) o ve como texto. O membro da comissao le a
  # carta pela tela da candidatura e fica sem o codigo.
  def access_token_column(record, column)
    process = record.admission_application.admission_process
    if can?(:manage, record)
      link_to record.access_token, admission_letter_url(
        admission_id: process.simple_id, id: record.access_token
      )
    elsif can?(:manage, process)
      record.access_token
    end
  end
end

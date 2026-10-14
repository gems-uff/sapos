# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Model Concern que mantem o nome do usuario associado igual ao do registro.
# Student#name e Professor#name sao a fonte de verdade: o usuario nasce com uma
# copia do nome (Enrollment#create_user!) ou recebe um nome digitado na tela de
# usuarios, e sem esta propagacao os dois divergem para sempre na primeira
# correcao -- inclusive troca de sobrenome, acento e typo, nao so caixa alta.
#
# O nome divergente aparece nos templates de e-mail do Devise, na autoria de
# comentario de inscricao e em todo to_label que parte de user.name.
module UserNameSyncConcern
  extend ActiveSupport::Concern

  included do
    after_save :sync_name_to_user, if: :should_sync_name_to_user?
  end

  private
    # Dois gatilhos, nao um. A correcao do nome e o caso comum; a ligacao de um
    # usuario que ja existia a um registro que ja existia e o outro, e nele os
    # dois nomes chegam prontos e diferentes. Por ser after_save, alcanca tambem
    # o registro que nasce ja apontando para um usuario.
    def should_sync_name_to_user?
      saved_change_to_name? || saved_change_to_user_id?
    end

    # A gravacao pula a validacao de proposito. As validacoes de User tratam de
    # papel e de associacao, nunca do nome, e reprovam o save sempre que quem
    # edita o registro esta abaixo do usuario dele em Role::ORDER -- secretaria
    # editando aluno que tambem e administrador, por exemplo. Validar aqui
    # devolveria justamente a divergencia que esta propagacao existe para
    # eliminar, e em silencio: o aluno salva, o usuario nao. O paper_trail
    # registra a mudanca do mesmo jeito.
    #
    # O guarda e sobre a associacao, nao sobre user_id: ponteiro pendurado deixa
    # user_id preenchido com user nil.
    def sync_name_to_user
      return if user.blank?
      user.name = name
      user.save(validate: false)
    end
end

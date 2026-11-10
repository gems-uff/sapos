# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Quem grava uma linha de autoria tem de poder alterar o artigo dela. O Ability
# confere a linha como está no banco, e libera a criação à classe, porque o
# subform do artigo precisa dela; a validação confere o artigo para onde a
# linha vai -- o de uma linha nova, ou o de uma linha movida. Artigo ainda não
# salvo é o do subform de quem o está criando. Fora de uma requisição não há
# usuário, e não há o que conferir.
module PaperAuthorshipGuardConcern
  extend ActiveSupport::Concern

  included do
    validate :paper_editable_by_current_user
  end

  private
    def paper_editable_by_current_user
      return if current_user.blank? || paper.nil? || paper.new_record?
      return if Ability.new(current_user).can?(:update, paper)

      errors.add(:paper, :cannot_edit_other_papers)
    end
end

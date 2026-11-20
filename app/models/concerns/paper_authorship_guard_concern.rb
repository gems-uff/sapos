# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Quem grava uma linha de autoria tem de poder alterar o artigo dela. O Ability
# confere a linha como está no banco, e libera a criação à classe, porque o
# subform do artigo precisa dela; a validação confere o artigo para onde a
# linha vai -- o de uma linha nova, ou o de uma linha movida -- e, na linha
# movida, também o artigo de onde ela sai: o subform do artigo aceita pelo id
# uma linha que já existe, e a de outro artigo viria para o de quem envia.
# Artigo ainda não salvo é o do subform de quem o está criando. Fora de uma
# requisição não há usuário, e não há o que conferir.
module PaperAuthorshipGuardConcern
  extend ActiveSupport::Concern

  included do
    validate :paper_editable_by_current_user
  end

  private
    def paper_editable_by_current_user
      return if current_user.blank? || paper.nil? || paper.new_record?

      ability = Ability.new(current_user)
      papers = [paper]
      papers << Paper.find_by(id: paper_id_in_database) if persisted? && paper_id_changed?
      return if papers.compact.all? { |a_paper| ability.can?(:update, a_paper) }

      errors.add(:paper, :cannot_edit_other_papers)
    end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# O professor que lança nota só altera os campos de nota da turma e das
# inscrições dela; quem diz se ele lança nota ali é o Ability, pelo dono da
# turma. A pergunta vai pelo registro como está no banco e pelo registro
# alterado: perguntar só pelo alterado deixaria a troca do dono escapar da
# validação, porque a turma já de outro professor não seria mais "dele".
module GradePostingGuardConcern
  extend ActiveSupport::Concern

  def restricted_to_grade_fields?
    return false unless cannot?(:update_all_fields, self)

    [persisted_state, self].compact.any? { |record| can?(:post_grades, record) }
  end

  private
    def persisted_state
      self.class.unscoped.find_by(id: id) if persisted?
    end
end

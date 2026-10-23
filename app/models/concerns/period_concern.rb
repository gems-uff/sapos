# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Registro que vale de start_date a end_date (nulo = em aberto). Períodos do
# mesmo grupo não podem se cruzar, senão o on_date do modelo casaria duas
# linhas para a mesma data.
#
# - scope: colunas que definem o grupo.
# - parent/siblings: o pai cujo subform manda várias linhas no mesmo envio, e
#   a coleção dele. Sem subform, omita os dois.
# - end_inclusive: se o dia do end_date ainda vale; tem de casar com o on_date.
module PeriodConcern
  extend ActiveSupport::Concern

  included do
    class_attribute :period_scope, :period_parent, :period_siblings,
      :period_end_inclusive, instance_writer: false
  end

  class_methods do
    def period(scope:, end_inclusive:, parent: nil, siblings: nil)
      self.period_scope = scope
      self.period_parent = parent
      self.period_siblings = siblings
      self.period_end_inclusive = end_inclusive
      validate :no_overlapping_period, if: :period_changed?
    end
  end

  private
    # Só a linha nova ou editada é julgada: o subform regrava todas as linhas,
    # e um registro antigo intocado não pode impedir de salvar o pai.
    def period_changed?
      new_record? ||
        (period_scope + [:start_date, :end_date]).any? do |column|
          will_save_change_to_attribute?(column)
        end
    end

    # end_date nulo vale como infinito. Compara por to_date, como o DATE() dos
    # on_date.
    def no_overlapping_period
      return if start_date.blank? || period_scope_incomplete?
      if other_periods.any? { |other| overlaps?(other) }
        errors.add(:base, :overlapping_period)
      end
    end

    # Coluna do grupo em branco: a presença reprova, e consultar por nulo
    # casaria outra linha em branco. Exceção: a chave do pai ainda não gravado,
    # em que estar no subform dele é o que põe a linha no grupo.
    def period_scope_incomplete?
      period_scope.any? do |column|
        self[column].blank? &&
          !(column == period_parent_key && public_send(period_parent).present?)
      end
    end

    # As linhas que o subform criou ou alterou são lidas da memória: comparar
    # com o banco recusaria mover a fronteira entre dois períodos no mesmo
    # envio. "Alterada" se decide no subform inteiro, antes de filtrar pelo
    # grupo; senão a cópia do banco de uma linha que trocou de professor
    # acusaria sobreposição. As demais vêm do banco, porque a coleção em
    # memória pode estar velha. Linha removida do subform já foi apagada pelo
    # writer da associação antes da validação.
    def other_periods
      edited = period_form_rows.select { |row| row.new_record? || row.changed? }
      pending = edited.select do |row|
        (period_scope - [period_parent_key]).all? { |column| row[column] == self[column] }
      end
      conditions = period_scope.index_with { |column| self[column] }
      return pending if conditions.values.any?(&:blank?)
      stored = self.class.where(conditions).where.not(id: [id, *edited.map(&:id)].compact)
      stored.to_a + pending
    end

    def period_form_rows
      return [] if period_parent.nil?
      parent = public_send(period_parent)
      return [] if parent.nil?
      parent.association(period_siblings).target
        .reject { |row| row.equal?(self) || (id.present? && row.id == id) }
    end

    def period_parent_key
      return nil if period_parent.nil?
      self.class.reflect_on_association(period_parent).foreign_key.to_sym
    end

    def overlaps?(other)
      return false if other.start_date.blank?
      (other.end_date.nil? || starts_before_end?(start_date, other.end_date)) &&
        (end_date.nil? || starts_before_end?(other.start_date, end_date))
    end

    # Com término inclusivo, começar no próprio dia do término cruza.
    def starts_before_end?(start, finish)
      if period_end_inclusive
        start.to_date <= finish.to_date
      else
        start.to_date < finish.to_date
      end
    end
end

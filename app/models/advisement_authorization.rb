# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Indicates that a Professor is accredited to advise at a Level during a period.
# Each row is one accreditation period: start_date is the accreditation date and
# end_date the last day the accreditation was valid (nil while still open). A
# professor can be accredited, de-accredited and re-accredited over time, so the
# history is kept as several rows per (professor, level) instead of a single one.
class AdvisementAuthorization < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :level, optional: false

  validates :professor, presence: true
  validates :level, presence: true
  validates :start_date, presence: true
  validates_date :end_date, on_or_after: :start_date, allow_blank: true
  validate :no_overlapping_authorization, if: :period_changed?

  # Rows whose accreditation period contains +date+ — the SQL analog of
  # #active_on?. Inclusive on both ends: the end_date day still counts as active.
  # start_date/end_date are wrapped in DATE() so a stored time-of-day never shifts
  # the comparison (the same reason Affiliation#on_date does it), matching the
  # to_date coercion #active_on? uses in Ruby.
  scope :on_date, ->(date) {
    where(
      "DATE(advisement_authorizations.start_date) <= :date AND " \
      "(advisement_authorizations.end_date IS NULL OR " \
      "DATE(advisement_authorizations.end_date) >= :date)",
      date: date
    )
  }

  def to_label
    "#{level.name}"
  end

  # True when the accreditation period contains +date+. An open period
  # (end_date nil) has not been closed, so it covers any date from start_date on.
  # The end_date day itself still counts as active (inclusive), matching the
  # on_date scope.
  def active_on?(date)
    return false if start_date.blank?
    start_date.to_date <= date && (end_date.nil? || date <= end_date.to_date)
  end

  private
    # Só a linha nova ou editada é julgada. A main não tinha regra de
    # unicidade, e a migration das datas deixou abertas as linhas antigas: uma
    # duplicata herdada que ninguém tocou não pode impedir de salvar o Nível
    # inteiro, cujo subform regrava todas as linhas. Quem edita a duplicata
    # continua obrigado a deixá-la disjunta.
    def period_changed?
      new_record? ||
        will_save_change_to_professor_id? || will_save_change_to_level_id? ||
        will_save_change_to_start_date? || will_save_change_to_end_date?
    end

    # Um professor não pode ter dois credenciamentos que se sobrepõem no mesmo
    # nível: o histórico é uma sequência de períodos disjuntos. Trata end_date
    # nulo como infinito, então um período aberto sobrepõe qualquer outro que
    # comece depois do seu start_date. Os dois limites são inclusivos, coerente
    # com #active_on? e a scope #on_date: um período que termina em 31/12 e
    # outro que começa em 01/01 são disjuntos, mas se ambos compartilhassem o
    # mesmo dia (um termina e o outro começa nele) seriam sobrepostos -- os dois
    # valeriam nesse dia. to_date é necessário porque a migration copiou
    # created_at (com hora) para start_date nas linhas antigas.
    def no_overlapping_authorization
      return if professor_id.blank? || level.blank? || start_date.blank?
      if other_periods.any? { |other| overlaps?(other) }
        errors.add(:base, :overlapping_authorization)
      end
    end

    # As outras linhas do mesmo professor e nível. As que o subform de Nível
    # criou, alterou ou removeu no mesmo envio são lidas da memória: ele
    # valida todas as linhas antes de gravar qualquer uma, e comparar com o
    # banco recusaria mover a fronteira entre dois períodos, porque cada linha
    # colidiria com a data ainda gravada da vizinha. Na criação do Nível o
    # level_id ainda não existe, então o que diz que a linha é do mesmo nível
    # é estar no subform dele.
    #
    # Linha em memória que o envio não tocou vem do banco, e não da memória:
    # coleção carregada antes pode estar velha -- apagada, ou com um id que o
    # SQLite reaproveitou depois de um rollback.
    def other_periods
      in_form = level.association(:advisement_authorizations).target
        .select { |auth| auth.professor_id == professor_id }
        .reject { |auth| auth.equal?(self) || (id.present? && auth.id == id) }
      edited = in_form.select do |auth|
        auth.marked_for_destruction? || auth.new_record? || auth.changed?
      end
      pending = edited.reject(&:marked_for_destruction?)
      return pending if level_id.blank?
      stored = AdvisementAuthorization
        .where(professor_id: professor_id, level_id: level_id)
        .where.not(id: [id, *edited.map(&:id)].compact)
      stored.to_a + pending
    end

    def overlaps?(other)
      return false if other.start_date.blank?
      (other.end_date.nil? || other.end_date.to_date >= start_date.to_date) &&
        (end_date.nil? || other.start_date.to_date <= end_date.to_date)
    end
end

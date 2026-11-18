# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Reconstrói pelo paper_trail os períodos de credenciamento, para a migration
# que cria start_date/end_date. Antes dela, descredenciar era apagar a linha, e
# cada versão destroy guarda professor, nível e created_at: cada ciclo de
# criação e remoção vira um período. Precedentes, que andavam pelo
# previous_version das linhas vivas: 20240524135850_create_affiliation.rb e
# 20240527174758_create_program_level.rb.
#
# Grava sem validação e sem paper_trail: a reconstrução não é ação de usuário,
# e o versions continua registrando só o que aconteceu de fato.
class AdvisementAuthorizationHistory
  # Folga até a qual dois períodos do mesmo professor e nível viram um só:
  # apagar e recriar perto é correção de cadastro, não descredenciamento.
  TOLERANCE_DAYS = 30

  # Versão antiga pode trazer tag que o app não permite no YAML
  # (config.active_record.yaml_column_permitted_classes).
  PERMITTED_CLASSES = [
    Symbol, Date, Time, DateTime,
    ActiveSupport::TimeWithZone, ActiveSupport::TimeZone,
    ActiveSupport::HashWithIndifferentAccess
  ].freeze

  Period = Struct.new(:professor_id, :level_id, :start_date, :end_date, :live_ids, keyword_init: true)

  attr_reader :inserted, :removed_duplicates, :skipped_periods,
    :unreadable_version_ids, :vanished_item_ids

  def initialize
    @inserted = 0
    @skipped_periods = 0
    @removed_duplicates = []
    @unreadable_version_ids = []
    @vanished_item_ids = []
  end

  def rebuild!
    periods = merge(intervals)
    move_first_start_to_first_admission(periods)
    write(periods)
    self
  end

  # Matrículas desligadas sem orientador credenciado no nível no mês do
  # desligamento -- a regra de Enrollment#enrollment_has_authorized_advisor,
  # que recusaria a próxima edição delas.
  def dismissed_without_accredited_advisor
    Enrollment.joins(:dismissal)
      .includes(:level, :dismissal, advisements: { professor: { advisement_authorizations: :level } })
      .find_each.filter_map { |enrollment| enrollment.id if uncovered?(enrollment) }
  end

  private
    # Um intervalo por estado de cada linha, de quando ele passou a valer até o
    # evento seguinte; nil no fim se a linha ainda existe. O object de update e
    # destroy guarda o estado ANTERIOR ao evento, e o create não guarda nada.
    # Cada create abre um ciclo novo: o MySQL antigo reaproveitava id.
    def intervals
      live = AdvisementAuthorization.pluck(:id, :professor_id, :level_id, :created_at).index_by(&:first)
      versions = PaperTrail::Version.where(item_type: "AdvisementAuthorization").order(:id)
        .pluck(:id, :item_id, :event, :created_at, :object).group_by(&:second)

      (versions.keys | live.keys).flat_map do |item_id|
        result = []
        start = nil # início do estado corrente; nil fora de ciclo
        versions.fetch(item_id, []).each do |version_id, _, event, at, object|
          if event == "create"
            @vanished_item_ids << item_id if start
            start = at
            next
          end
          state = load_state(version_id, object)
          from = local_date(start || state&.dig("created_at"))
          if state && from
            result << Period.new(professor_id: state["professor_id"], level_id: state["level_id"],
                                 start_date: from, end_date: local_date(at), live_ids: [])
          elsif state
            @unreadable_version_ids << version_id
          end
          start = (event == "update" ? at : nil)
        end

        if (row = live[item_id])
          id, professor_id, level_id, created_at = row
          result << Period.new(professor_id: professor_id, level_id: level_id,
                               start_date: local_date(start || created_at), end_date: nil, live_ids: [id])
        elsif start
          @vanished_item_ids << item_id
        end
        result
      end
    end

    # Por (professor, nível), funde os que se cruzam ou ficam a até
    # TOLERANCE_DAYS um do outro. Linha viva é período aberto, então todas as
    # vivas do par caem no último: a duplicata herdada vira um período só.
    def merge(intervals)
      intervals.group_by { |period| [period.professor_id, period.level_id] }.transform_values do |list|
        list.sort_by(&:start_date).each_with_object([]) do |period, merged|
          last = merged.last
          if last && (last.end_date.nil? || period.start_date - last.end_date <= TOLERANCE_DAYS)
            last.end_date = nil if period.end_date.nil?
            last.end_date = [last.end_date, period.end_date].max if last.end_date
            last.live_ids |= period.live_ids
          else
            merged << period.dup
          end
        end
      end
    end

    # A linha costuma ter sido cadastrada em lote na implantação, anos depois
    # de o credenciamento valer. O primeiro período de cada par recua até a
    # admissão da primeira matrícula daquele nível em que o professor é
    # orientador principal -- a heurística dos precedentes, que usavam a
    # primeira banca.
    def move_first_start_to_first_admission(periods)
      admissions = Advisement.joins(:enrollment).where(main_advisor: true)
        .group("advisements.professor_id", "enrollments.level_id")
        .minimum("enrollments.admission_date")
      periods.each do |pair, list|
        admission = admissions[pair]&.to_date
        list.first.start_date = [list.first.start_date, admission].min if admission
      end
    end

    # O período com linha viva fica nela (a de menor id) e as demais vivas do
    # par são apagadas; os encerrados entram como linhas novas. Professor ou
    # nível que não existe mais não ganha linha: o nível apagado leva junto os
    # credenciamentos, e a versão destroy deles continua no versions.
    def write(periods)
      professors = Professor.where(id: periods.keys.map(&:first)).pluck(:id).to_set
      levels = Level.where(id: periods.keys.map(&:last)).pluck(:id).to_set
      rows = []

      AdvisementAuthorization.transaction do
        periods.each do |(professor_id, level_id), list|
          list.each do |period|
            if period.live_ids.any?
              keep, *duplicates = period.live_ids.sort
              AdvisementAuthorization.where(id: keep).update_all(start_date: period.start_date, end_date: nil)
              AdvisementAuthorization.where(id: duplicates).delete_all if duplicates.any?
              @removed_duplicates.concat(duplicates)
            elsif professors.include?(professor_id) && levels.include?(level_id)
              rows << { professor_id: professor_id, level_id: level_id,
                        start_date: period.start_date, end_date: period.end_date }
            else
              @skipped_periods += 1
            end
          end
        end
        AdvisementAuthorization.insert_all!(rows) if rows.any?
      end
      @inserted = rows.size
    end

    def load_state(version_id, object)
      state = YAML.safe_load(object.to_s, permitted_classes: PERMITTED_CLASSES, aliases: true)
      return state.stringify_keys if state.is_a?(Hash)
      @unreadable_version_ids << version_id
      nil
    rescue Psych::Exception
      @unreadable_version_ids << version_id
      nil
    end

    # Os instantes estão em UTC; o que vale é o dia no fuso da aplicação.
    def local_date(value)
      value = ActiveSupport::TimeZone["UTC"].parse(value) if value.is_a?(String)
      value&.in_time_zone&.to_date
    rescue ArgumentError
      nil
    end

    def uncovered?(enrollment)
      return false if enrollment.level.nil? || enrollment.advisements.empty?
      !enrollment.any_accredited_advisor?(enrollment.advisements)
    end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcessRanking < ActiveRecord::Base
  has_paper_trail

  belongs_to :ranking_config, optional: false,
    class_name: "Admissions::RankingConfig"
  belongs_to :admission_process, optional: false,
    class_name: "Admissions::AdmissionProcess"
  belongs_to :admission_phase, optional: true,
    class_name: "Admissions::AdmissionPhase"

  validate :that_phase_is_part_of_the_process

  def that_phase_is_part_of_the_process
    return if self.admission_phase.blank?
    return if self.admission_process.blank?
    self.admission_process.phases.each do |p|
      return if p.admission_phase == self.admission_phase
    end
    errors.add(:admission_phase, :phase_not_in_process)
  end

  def to_label
    "#{self.ranking_config.to_label} - #{self.admission_process.to_label}"
  end

  def generate_ranking
    # A failure keeps the results of the previous run
    self.class.transaction do
      # Two runs at once could both create the result of a candidate
      Admissions::RankingConfig.lock.find(self.ranking_config_id)
      candidates = self.rank_candidates
      self.clear_results(candidates)
      candidates
    end
  end

  # Candidates that the previous run ranked and this one does not lose their
  # position and machine, as if never ranked: an empty field would still be
  # read by conditions and other rankings. Those ranked again keep theirs, and
  # are written only where something changed.
  def clear_results(candidates)
    rconfig = self.ranking_config
    ranked = candidates.filter_map { |c| c[:__ranking_result].id if !c[:__position].nil? }
    Admissions::AdmissionRankingResult.where(
      ranking_config_id: rconfig.id,
      admission_application_id: self.admission_process.admission_applications.select(:id)
    ).where.not(id: ranked).each do |result|
      result.filled_form.fields.where(
        form_field_id: [rconfig.position_field_id, rconfig.machine_field_id]
      ).destroy_all
      result.filled_form.update!(is_filled: false)
    end
  end

  def rank_candidates
    rconfig = self.ranking_config
    admission_applications = self.admission_process.admission_applications
    columns = self.ranking_config.ranking_columns.all
    candidates = self.filter_sort_candidates(columns, admission_applications)
    position = 1
    groups = {}
    process_vacancies = {}
    readjust_groups = {}
    rconfig.ranking_groups.each do |g|
      groups[g.name] = g.total_vacancies
      readjust_groups[g.name] = 0
    end
    # Configurations saved before the validation of groups, or a group renamed
    # on its own, would leave a process without a limit of group
    rconfig.ranking_processes.each do |process|
      next if process.group.blank? || groups.key?(process.group)
      raise Exceptions::MissingGroupException.new(I18n.t(
        "errors.admissions/admission_process_ranking.group_not_found",
        group: process.group
      ))
    end

    machine_should_raise = [
      Admissions::RankingConfig::EXCEPTION_CONDITION,
      Admissions::RankingConfig::EXCEPTION_ON_MACHINE,
    ].include?(self.ranking_config.behavior_on_invalid_condition) ?
      Admissions::FormCondition::RAISE_MACHINE : nil

    steps = rconfig.ranking_processes.distinct.pluck(:step).sort
    steps.each do |step|
      processes = rconfig.ranking_processes.where(step: step).order(:order).select do |process|
        remaing_vacancies = process.calculate_remaining(groups, process_vacancies)
        process_vacancies[process.id] = remaing_vacancies
        remaing_vacancies > 0
      end
      # Candidates tied in every column are ranked together. Each one enters the
      # first process it satisfies among those with a vacancy, of their own and
      # of their group, when the tie is reached: once another of them takes the
      # last one, the others still enter beyond the vacancies, and the excess
      # is taken from the next step. Those of the same process share a
      # position, and the processes keep their order.
      candidates.chunk_while do |first, second|
        Admissions::AdmissionProcessRanking.compare_candidates(columns, first, second) == 0
      end.each do |tied|
        open = processes.select { |p| p.calculate_remaining(groups, process_vacancies) > 0 }
        entered = {}
        tied.each do |candidate|
          next if !candidate[:__position].nil?
          process = open.find do |p|
            candidate[:__candidate].satisfies_condition(
              p.ranking_machine.form_condition,
              fields: candidate[:__fields],
              should_raise: machine_should_raise
            )
          end
          next if process.nil?
          if process.calculate_remaining(groups, process_vacancies) > 0
            process.decrease_vacancies!(groups, process_vacancies)
          else
            # Each process belongs to a single step: only its group carries the
            # excess to the next one
            process.decrease_group!(readjust_groups)
          end
          (entered[process] ||= []) << candidate
        end
        processes.each do |process|
          next if !entered.key?(process)
          machine = process.ranking_machine.name
          machine = "#{machine}/#{step}" if step != 1
          entered[process].each do |candidate|
            self.set_candidate_position(candidate, process, position, machine)
          end
          position += entered[process].size
        end
      end
      readjust_groups.each do |key, value|
        groups[key] += value
        readjust_groups[key] = 0
      end
    end
    candidates
  end

  def set_candidate_position(candidate, process, position, machine)
    candidate[:__position] = position
    candidate[:__machine] = machine
    candidate[:__process] = process
    candidate[:__ranking_result].save
    candidate[:__ranking_result].filled_position.update!(value: position)
    candidate[:__ranking_result].filled_machine.update!(value: machine)
    candidate[:__ranking_result].filled_form.update!(is_filled: true)
  end

  def filter_sort_candidates(columns, admission_applications)
    form_condition = self.ranking_config.form_condition
    form_condition_should_raise = [
      Admissions::RankingConfig::EXCEPTION_CONDITION,
      Admissions::RankingConfig::EXCEPTION_ON_PRECONDITION,
    ].include?(self.ranking_config.behavior_on_invalid_condition) ?
      Admissions::FormCondition::RAISE_PRECONDITION : nil

    ranking_should_raise = (
      self.ranking_config.behavior_on_invalid_ranking ==
        Admissions::RankingConfig::EXCEPTION_RANKING
    ) ? Admissions::FormCondition::RAISE_RANKING : nil

    admission_applications.filter_map do |candidate|
      fields = candidate.fields_hash

      next if !candidate.satisfies_condition(
        form_condition, fields:, should_raise: form_condition_should_raise
      )
      result = {
        __position: nil,
        __machine: nil,
        __ranking_result: nil,
        __candidate: candidate,
        __fields: fields
      }
      skip = false
      columns.each do |column|
        field = column.convert(fields[column.name])
        if field.nil?
          raise Exceptions::MissingFieldException.new(I18n.t(
            "errors.admissions/admission_process_ranking.field_not_found",
            field: column.name, source: ranking_should_raise
          )) if ranking_should_raise.present?
          skip = true
          break
        end
        result[column.name] = field
      end
      next if skip
      result[:__ranking_result] = Admissions::AdmissionRankingResult.find_or_create_by(
        admission_application_id: candidate.id,
        ranking_config_id: self.ranking_config_id,
      )
      result
    end.sort do |first, second|
      Admissions::AdmissionProcessRanking.compare_candidates(columns, first, second)
    end
  end

  def self.compare_candidates(columns, first, second)
    comparision = 0
    columns.each_with_index do |column, i|
      break if comparision != 0 && i != 0
      comparision = column.compare(first[column.name], second[column.name])
    end
    comparision
  end
end

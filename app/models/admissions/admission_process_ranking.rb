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
    self.admission_process.phases.each do |p|
      return if p.admission_phase == self.admission_phase
    end
    errors.add(:admission_phase, :phase_not_in_process)
  end

  def to_label
    "#{self.ranking_config.to_label} - #{self.admission_process.to_label}"
  end

  def generate_ranking
    rconfig = self.ranking_config
    admission_applications = self.admission_process.admission_applications
    candidates = self.filter_sort_candidates(admission_applications)
    position = 1
    groups = {}
    process_vacancies = {}
    rconfig.ranking_groups.each do |g|
      groups[g.name] = g.total_vacancies
    end
    steps = rconfig.ranking_processes.distinct.pluck(:step).sort
    steps.each do |step|
      processes = rconfig.ranking_processes.where(step: step).order(:order).select do |process|
        remaing_vacancies = process.calculate_remaining(groups, process_vacancies)
        process_vacancies[process.id] = remaing_vacancies
        remaing_vacancies > 0
      end
      candidates.each do |candidate|
        next if !candidate[:__position].nil?
        processes.each do |process|
          if candidate[:__candidate].satisfies_conditions(
            process.ranking_machine.form_conditions,
            fields: candidate[:__fields]
          )
            machine = process.ranking_machine.name
            machine = "#{machine}/#{step}" if step != 1
            candidate[:__position] = position
            candidate[:__machine] = machine
            candidate[:__ranking_result].save
            candidate[:__ranking_result].filled_position.update!(value: position)
            candidate[:__ranking_result].filled_machine.update!(value: machine)
            candidate[:__ranking_result].filled_form.update!(is_filled: true)
            position += 1
            if !process.decrease_vacancies_and_check_remaining!(groups, process_vacancies)
              processes.delete(process)
            end
            break
          end
        end
      end
    end
    candidates
  end

  def filter_sort_candidates(admission_applications)
    columns = self.ranking_config.ranking_columns.all
    admission_applications.filter_map do |candidate|
      fields = candidate.fields_hash
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
      comparision = 0
      columns.each_with_index do |column, i|
        break if comparision != 0 && i != 0
        comparision = column.compare(first[column.name], second[column.name])
      end
      comparision
    end
  end
end

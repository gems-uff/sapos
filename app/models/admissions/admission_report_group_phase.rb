# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupPhase < Admissions::AdmissionReportGroupBase
  def prepare_config
    flat_columns = self.flat_columns({})
    @columns = self.group_columns(flat_columns)
    self.prepare_header
  end

  def prepare_header
    mode_names = {
      shared: Admissions::AdmissionPhaseResult::SHARED,
      consolidation: Admissions::AdmissionPhaseResult::CONSOLIDATION
    }
    @columns.each do |phase_columns|
      phase_columns[:columns].each do |mode_columns|
        mode = mode_columns[:mode]
        mode_columns[:result_type] = mode_names[mode]
        if mode_columns[:result_type].present?
          if @config.group_column
            @header << "#{phase_columns[:phase].name} - #{mode_columns[:result_type]}"
          end
          mode_columns[:columns].each do |column|
            @header << column[:header]
          end
        else
          member_ids = []
          @applications.each do |application|
            app_members = application.pendencies.where(
              mode: Admissions::AdmissionPendency::MEMBER,
              admission_phase_id: phase_columns[:phase].id
            ).distinct.pluck(:user_id).compact
            member_ids |= app_members
          end
          mode_columns[:members] = User.where(id: member_ids).order(:name)
          mode_columns[:members].each do |member|
            if @config.group_column
              @header << "#{phase_columns[:phase].name} - #{member.name}"
            end
            mode_columns[:columns].each do |column|
              @header << column[:header]
            end
          end
        end
      end
    end
    self
  end

  def prepare_group_row(row, cell_index, application, &block)
    @columns.each do |phase_columns|
      phase_columns[:columns].each do |mode_columns|
        if mode_columns[:result_type].present?
          if @config.group_column
            row << mode_columns[:result_type]
            cell_index += 1
          end
          result = application.results.where(
            admission_phase_id: mode_columns[:phase].id,
            mode: mode_columns[:result_type]
          ).first
          cell_index = populate_filled(
            row, cell_index, result.try(:filled_form),
            mode_columns[:columns], &block
          )
        else
          mode_columns[:members].each do |member|
            if @config.group_column
              row << member.name
              cell_index += 1
            end
            evaluation = application.evaluations.where(
              admission_phase_id: mode_columns[:phase].id,
              user_id: member.id
            ).first
            cell_index = populate_filled(
              row, cell_index, evaluation.try(:filled_form),
              mode_columns[:columns], &block
            )
          end
        end
      end
    end
    cell_index
  end

  private
    def flat_form(column_map, columns, phase, phase_num, mode, template)
      phase_fields = report_template_fields(template)
      if !@config.group_column
        phase_fields = phase_fields.no_group
      end
      phase_fields = phase_fields.no_html
      phase_fields.each do |field|
        names = [
          field.name,
          "#{phase_num}.#{field.name}",
          "#{phase.name}.#{field.name}",
          "#{phase_num}.#{mode}.#{field.name}",
          "#{phase.name}.#{mode}.#{field.name}"
        ]
        column = {
          header: field.name,
          mode: mode,
          field: field,
          admission_phase_id: phase.id,
          phase: phase,
          names: names
        }
        names.each do |name|
          (column_map[name] ||= []) << column
        end
        columns << column
      end
    end

    def flat_columns(column_map)
      order = @extra[:reverse] ? :desc : :asc
      all_flat = []
      size = @admission_process.phases.size
      @admission_process.phases.order(order: order).each_with_index do |p, index|
        phase = p.admission_phase
        phase_num = @extra[:reverse] ? (size - index) : (index + 1)
        if phase.shared_form.present?
          flat_form(column_map, all_flat, phase, phase_num, :shared, phase.shared_form)
        end
        if phase.member_form.present? && !@extra[:hide_committee]
          flat_form(column_map, all_flat, phase, phase_num, :member, phase.member_form)
        end
        if phase.consolidation_form.present?
          flat_form(column_map, all_flat, phase, phase_num, :consolidation, phase.consolidation_form)
        end
      end

      report_columns = @group.columns.order(:order).map(&:name)
      result = []
      if @group.operation == Admissions::AdmissionReportGroup::INCLUDE
        report_columns.each do |name|
          (column_map[name] || []).each do |column|
            result << column
          end
        end
      else
        result = all_flat.filter do |column|
          (column[:names] & report_columns).empty?
        end
      end
      result
    end

    def group_columns(flat_columns)
      columns = []
      by_phase = {}
      flat_columns.each do |column|
        phase_id = column[:admission_phase_id]
        phase = by_phase[phase_id]
        if phase.nil?
          phase = {
            admission_phase_id: phase_id,
            mode: :phase,
            phase: column[:phase],
            columns: [column]
          }
          by_phase[phase_id] = phase
          columns << phase
        else
          phase[:columns] << column
        end
      end
      columns.map { |phase_column| self.group_phase_mode_columns(phase_column) }
    end

    def group_phase_mode_columns(phase_column)
      columns = []
      phase_id = phase_column[:admission_phase_id]
      by_mode = {}
      phase_column[:columns].each do |column|
        mode = by_mode[column[:mode]]
        if mode.nil?
          mode = {
            admission_phase_id: phase_id,
            phase: column[:phase],
            mode: column[:mode],
            columns: [column]
          }
          by_mode[column[:mode]] = mode
          columns << mode
        else
          mode[:columns] << column
        end
      end
      {
        admission_phase_id: phase_id,
        phase: phase_column[:phase],
        mode: :phase,
        columns: columns
      }
    end
end

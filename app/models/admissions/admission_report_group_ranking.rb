# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupRanking < Admissions::AdmissionReportGroupBase
  def prepare_config
    flat_columns = self.flat_columns({})
    @columns = self.group_columns(flat_columns)
    self.prepare_header
  end

  def prepare_header
    @columns.each do |ranking_columns|
      if @config.group_column
        @header << "#{ranking_columns[:ranking_config].name}"
      end
      ranking_columns[:columns].each do |column|
        @header << column[:header]
      end
    end
    self
  end

  def prepare_group_row(row, cell_index, application, &block)
    @columns.each do |ranking_columns|
      if @config.group_column
        row << "#{ranking_columns[:ranking_config].name}"
        cell_index += 1
      end
      ranking = application.rankings.where(
        ranking_config_id: ranking_columns[:ranking_config].id
      ).first
      cell_index = populate_filled(
        row, cell_index, ranking.try(:filled_form),
        ranking_columns[:columns], &block
      )
    end
    cell_index
  end

  private
    def flat_columns(column_map)
      all_flat = []
      @admission_process.rankings.each_with_index do |apr, index|
        ranking = apr.ranking_config
        ranking_num = index + 1

        ranking_fields = report_template_fields(ranking.form_template)
        if !@config.group_column
          ranking_fields = ranking_fields.no_group
        end
        ranking_fields = ranking_fields.no_html
        ranking_fields.each do |field|
          names = [
            field.name,
            "#{ranking_num}.#{field.name}",
            "#{ranking.name}.#{field.name}",
          ]
          if field == ranking.position_field
            names += [
              Admissions::RankingConfig::POSITION,
              "#{ranking_num}.#{Admissions::RankingConfig::POSITION}",
              "#{ranking.name}.#{Admissions::RankingConfig::POSITION}",
            ]
          elsif field == ranking.machine_field
            names += [
              Admissions::RankingConfig::MACHINE,
              "#{ranking_num}.#{Admissions::RankingConfig::MACHINE}",
              "#{ranking.name}.#{Admissions::RankingConfig::MACHINE}",
            ]
          end
          column = {
            header: field.name,
            mode: :field,
            field: field,
            ranking_config_id: ranking.id,
            ranking_config: ranking,
            names: names
          }
          names.each do |name|
            (column_map[name] ||= []) << column
          end
          all_flat << column
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
      by_ranking = {}
      flat_columns.each do |column|
        ranking_id = column[:ranking_config_id]
        ranking = by_ranking[ranking_id]
        if ranking.nil?
          ranking = {
            ranking_config_id: ranking_id,
            ranking_config: column[:ranking_config],
            mode: :ranking,
            columns: [column]
          }
          by_ranking[ranking_id] = ranking
          columns << ranking
        else
          ranking[:columns] << column
        end
      end
      columns
    end
end

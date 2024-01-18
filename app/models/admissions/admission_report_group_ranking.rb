# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionReportGroupRanking < Admissions::AdmissionReportGroupBase
  def prepare_config
    columns = self.group_columns(self.flat_columns({}))
    columns.each do |ranking_columns|
      next if @config.hide_empty_sections && Admissions::AdmissionRankingResult.includes(
        :admission_application
      ).where(
        admission_application: { admission_process_id: @admission_process.id },
        ranking_config_id: ranking_columns[:ranking_config].id
      ).blank?
      @sections << {
        title: "#{ranking_columns[:ranking_config].name}",
        columns: ranking_columns[:columns].map(&:dup),
        ranking_config: ranking_columns[:ranking_config]
      }
    end
  end

  def application_sections(application, &block)
    @sections.each do |section|
      ranking = application.rankings.where(
        ranking_config_id: section[:ranking_config].id
      ).first
      section[:application_columns] = populate_filled(
        ranking.try(:filled_form), section[:columns], &block
      )
    end
  end

  private
    def flat_columns(column_map)
      all_flat = []
      @admission_process.rankings.order(order: :desc).each_with_index do |apr, index|
        ranking = apr.ranking_config
        ranking_num = index + 1

        ranking_fields = report_template_fields(ranking.form_template)
        ranking_fields = ranking_fields.no_group
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

      report_columns = @group.columns.sort_by(&:order).map(&:name)
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

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module EnrollmentHelperConcern
  def custom_deferral_approval_date_form_column(record, options)
    month_year_widget(
      record, options, :approval_date, required: false
    )
  end

  def custom_accomplishment_conclusion_date_form_column(record, options)
    month_year_widget(
      record, options, :conclusion_date, required: false
    )
  end

  def custom_dismissal_date_form_column(record, options)
    month_year_widget(record, options, :date, required: false)
  end

  def custom_admission_date_form_column(record, options)
    month_year_widget(record, options, :admission_date)
  end

  def custom_level_form_column(record, options)
    fixed_level = (
      record.dismissal ||
      record.accomplishments.count > 0 ||
      record.deferrals.count > 0
    ) && record.level
    if fixed_level
      return html_escape(record.level.name)
    end
    column = EnrollmentsController.active_scaffold_config.columns[:level]
    active_scaffold_input_select column, options
  end

  # TODO: remove current accomplishments and current deferral_type if level was changed
  def custom_enrollment_options_for_association_conditions(association, record)
    if association.name == :phase
      Phase.find_all_for_enrollment(record.enrollment)
    elsif association.name == :deferral_type
      DeferralType.find_all_for_enrollment(record.enrollment)
    else
      "<not found>"
    end
  end

  def custom_research_area_form_column(record, options)
    research_areas = ResearchArea.where(available: true).to_a

    if record.research_area.present? && !record.research_area.available?
      research_areas << record.research_area
    end

    sorted_areas = research_areas.sort_by(&:name)

    select_options = options_for_select(
      sorted_areas.map { |ra| [ra.name, ra.id] },
      record.research_area_id
    )
    select_tag(options[:name], select_options, options.merge(prompt: as_(:_select_)))
  end

  def custom_research_line_form_column(record, options)
    if record.research_area.present?
      research_lines = ResearchLine.where(available: true,
       research_area: record.research_area).to_a
    else
      research_lines = ResearchLine.joins(:research_area)
      .where(available: true)
      .where(research_areas: { available: true })
      .to_a
    end

    if record.research_line.present? && !record.research_line.available?
      research_lines << record.research_line
    end

    sorted_lines = research_lines.sort_by(&:name)

    select_options = options_for_select(
      sorted_lines.map { |ra| [ra.name, ra.id] },
      record.research_line_id
    )
    select_tag(options[:name], select_options, options.merge(prompt: as_(:_select_)))
  end
end

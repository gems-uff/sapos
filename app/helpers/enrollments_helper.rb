# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Enrollments
module EnrollmentsHelper
  include PdfHelper
  include EnrollmentsPdfHelper

  include EnrollmentHelperConcern
  include ClassEnrollmentHelperConcern

  # EnrollmentHelperConcern
  alias_method(
    :deferral_approval_date_form_column,
    :custom_deferral_approval_date_form_column
  )
  alias_method(
    :accomplishment_conclusion_date_form_column,
    :custom_accomplishment_conclusion_date_form_column
  )
  alias_method(
    :dismissal_date_form_column,
    :custom_dismissal_date_form_column
  )
  alias_method(
    :admission_date_form_column,
    :custom_admission_date_form_column
  )
  alias_method(
    :level_form_column,
    :custom_level_form_column
  )

  # ClassEnrollmentHelperConcern
  alias_method(
    :class_enrollment_course_class_form_column,
    :custom_course_class_form_column
  )
  alias_method(
    :class_enrollment_disapproved_by_absence_form_column,
    :custom_disapproved_by_absence_form_column
  )
  alias_method(
    :class_enrollment_grade_form_column,
    :custom_grade_form_column
  )
  alias_method(
    :class_enrollment_grade_not_count_in_gpr_form_column,
    :custom_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :class_enrollment_obs_form_column,
    :custom_obs_form_column
  )
  alias_method(
    :class_enrollment_justification_grade_not_count_in_gpr_form_column,
    :custom_justification_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :field_attributes,
    :custom_field_attributes
  )

  # overriding dismissal date to_label
  def dismissal_column(record, input_name)
    I18n.localize(record.dismissal.to_label.to_date, format: :monthyear) if
      record.present? && record.dismissal.present?
  end

  # display the "user_type" field as a dropdown with options
  def scholarship_durations_active_search_column(record, input_name)
    select(
      :record, :scholarship_durations,
      options_for_select([["Sim", 1], ["Não", 0]]),
      { include_blank: as_(:_select_) },
      input_name
    )
  end

  def active_search_column(record, input_name)
    select(
      :record, :dismissal,
      options_for_select([["Sim", 1], ["Não", 0]]),
      { include_blank: as_(:_select_) },
      input_name
    )
  end

  def delayed_phase_search_column(record, input_name)
    local_options = { include_blank: false }
    select_html_options = { name: "search[delayed_phase][phase]" }
    day_html_options = { name: "search[delayed_phase][day]" }
    month_html_options = { name: "search[delayed_phase][month]" }
    year_html_options = { name: "search[delayed_phase][year]" }

    (
      select(
        :record, :phases,
        options_for_select([["Alguma", "all"]] +
          Phase.where(active: true).map { |phase| [phase.name, phase.id] }
        ),
        { include_blank: as_(:_select_) },
        select_html_options
      ) +
      label_tag(
        :delayed_phase_date,
        I18n.t("activerecord.attributes.enrollment.delayed_phase_date"),
        style: "margin: 0px 15px"
      ) +
      select_day(Date.today.day, local_options, day_html_options) +
      select_month(Date.today.month, local_options, month_html_options) +
      select_year(Date.today.year, local_options, year_html_options)
    )
  end

  def accomplishments_search_column(record, input_name)
    local_options = { include_blank: false }
    select_html_options = { name: "search[accomplishments][phase]" }
    day_html_options = { name: "search[accomplishments][day]" }
    month_html_options = { name: "search[accomplishments][month]" }
    year_html_options = { name: "search[accomplishments][year]"}

    (
      select(
        :record, :phases,
        options_for_select([["Todas", "all"]] +
          Phase.all.map { |phase| [phase.name, phase.id] }
        ),
        { include_blank: as_(:_select_) },
        select_html_options
      ) +
      label_tag(
        :accomplishments_date,
        I18n.t("activerecord.attributes.enrollment.accomplishment_date"),
        style: "margin: 0px 15px"
      ) +
      select_day(Date.today.day, local_options, day_html_options) +
      select_month(Date.today.month, local_options, month_html_options) +
      select_year(Date.today.year, local_options, year_html_options)
    )
  end

  def enrollment_hold_search_column(record, input_name)
    select_html_options = {
      name: "search[enrollment_hold][hold]",
      style: "float:left; margin: 5px 2px;"
    }
    check_box(record, :enrollment_hold, select_html_options)
  end

  def course_class_year_semester_search_column(record, options)
    disciplinas_filtro = Course.all.collect do |c|
      [I18n.transliterate(c.name.squish.downcase), c.name, c.id]
    end
    disciplinas_filtro.sort_by! { |elemento| elemento[0] }

    disciplinas_sem_nome_repetido = []
    ultimo_copiado = ""
    disciplinas_filtro.each do |elemento|
      if elemento[0] != ultimo_copiado
        disciplinas_sem_nome_repetido.push(elemento[1..2])
        ultimo_copiado = elemento[0]
      end
    end

    html = select_tag(
      "#{options[:name]}[course]",
      options_for_select(disciplinas_sem_nome_repetido),
      prompt: as_(:_select_),
      id: "#{options[:id]}_course",
      class: "as_search_search_course_class_option"
    )
    html << label_tag(
      "#{options[:id]}_year_semester",
      I18n.t("activerecord.attributes.enrollment.year_semester_label"),
      style: "margin: 0 15px;"
    )
    html << select_tag(
      "#{options[:name]}[year]",
      options_for_select(
        CourseClass.group(:year).select(:year).collect { |y| y[:year] }
      ),
      include_blank: as_(:_select_),
      id: "#{options[:id]}_year",
      class: "as_search_search_course_class_option"
    )
    html << select_tag(
      "#{options[:name]}[semester]",
      options_for_select(
        CourseClass.group(:semester).select(:semester)
        .collect { |y| y[:semester] }
      ),
      include_blank: as_(:_select_),
      id: "#{options[:id]}_semester",
      class: "as_search_search_course_class_option"
    )
    content_tag :span, html, class: "search_course_class"
  end

  def admission_date_search_column(record, options)
    month_year_widget(
      record, options, :admission_date, required: false, multiparameter: false,
      date_options: { prefix: options[:name] }
    )
  end

  def enrollment_admission_date_show_column(record, column)
    I18n.localize(record.admission_date, format: :monthyear)
  end

  def enrollment_dismissal_show_column(record, column)
    return "-" if record.dismissal.nil?
    "#{record.dismissal.dismissal_reason.name} - #{I18n.localize(
      record.dismissal.date, format: :monthyear
    )}"
  end

  def enrollment_advisements_show_column(record, column)
    return "-" if record.advisements.empty?
    render(partial: "enrollments/show_advisements_table",
           locals: { advisements: record.advisements,
                     show_enrollment_number: true })
  end

  def enrollment_deferrals_show_column(record, column)
    return "-" if record.deferrals.empty?
    render(partial: "enrollments/show_deferrals_table",
           locals: { deferrals: record.deferrals,
                     dateformat: :monthyear,
                     show_obs: true })
  end

  def enrollment_scholarship_durations_show_column(record, column)
    return "-" if record.scholarships.empty?
    render(partial: "enrollments/show_scholarships_table",
           locals: { scholarship_durations: record.scholarship_durations,
                     show_sponsor: false,
                     dateformat: :monthyear,
                     show_obs: true })
  end

  def enrollment_enrollment_holds_show_column(record, column)
    return "-" if record.enrollment_holds.empty?
    render(partial: "enrollments/show_holds_table",
           locals: { holds: record.enrollment_holds })
  end

  def enrollment_class_enrollments_show_column(record, column)
    return "-" if record.class_enrollments.empty?
    render(partial: "enrollments/show_class_enrollments_table",
           locals: { class_enrollments: record.class_enrollments,
                     show_obs: true })
  end

  def enrollment_thesis_defense_committee_participations_show_column(
    record, column
  )
    return "-" if record.thesis_defense_committee_participations.empty?
    render(
      partial: "enrollments/show_defense_committee_table",
      locals: {
        thesis_defense_committee_professors: record.thesis_defense_committee_professors,
        thesis_defense_date: record.thesis_defense_date,
        dismissal_date: record.dismissal.date
      }
    )
  end

  def enrollment_phase_due_dates_show_column(record, column)
    return "-" if record.completed_or_active_phase_completions.empty?
    render(
      partial: "enrollments/show_phases_table",
      locals: {
        phase_completions: record.completed_or_active_phase_completions,
        dateformat: :monthyear,
        show_obs: true
      }
    )
  end

  def readonly_dl_input(label, map, variable)
    "<dl>
      <dt><label for=\"field-#{variable}\">#{label}</label></dt>
      <dd><input name=\"#{variable}\"
                 class=\"fixed-text\"
                 value=\"#{map[variable]}\"
                 id=\"field-#{variable}\" readonly/></dd>
    </dl>".html_safe
  end

  def display_action_links(action_links, record, options, &block)
    search = search_params
    result = super
    if record.blank? || search.blank?
      return result
    end
    columns ||= list_columns
    if search[:delayed_phase].present? && search[:delayed_phase][:phase] == "all"
      phase_date = Date.new(
        search[:delayed_phase][:year].to_i,
        search[:delayed_phase][:month].to_i,
        search[:delayed_phase][:day].to_i
      )
      phases = record.delayed_phases(date: phase_date)
        .collect { |p| p.name }.join(", ")
      result += ("
        </tr></table></td>
        <tr class='record tr_search_result'>
          <td style='text-align: right;'>Etapas atrasadas</td>
          <td colspan='#{columns.size}'>#{phases}
            <table><tr>".html_safe).html_safe
    end

    searching_hold = (
      search[:enrollment_hold].present? &&
      search[:enrollment_hold][:hold].to_i != 0
    )
    if searching_hold
      holds = record.enrollment_holds.where(active: true)
        .collect(&:to_label).join(", ")
      result += ("
        </tr></table></td>
        <tr class='record tr_search_result'>
          <td style='text-align: right;'>Trancamento</td>
          <td colspan='#{columns.size}'>#{holds}
            <table><tr>".html_safe).html_safe
    end

    result
  end

  def options_for_association_conditions(association, record)
    result = custom_enrollment_options_for_association_conditions(association, record)
    return result if result != "<not found>"
    super
  end

  def permit_rs_browse_params
    [:page, :update, :utf8]
  end
end

class EnrollmentsController < ApplicationController
  active_scaffold :enrollment do |config|

    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection

    config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal]
    config.list.sorting = {:enrollment_number => 'ASC'}
    config.create.label = :create_enrollment_label
    config.update.label = :update_enrollment_label
#    config.columns[:level].update_columns = :accomplishments
    config.columns[:accomplishments].allow_add_existing = false;

    config.columns.add :scholarship_durations_active, :active, :professor, :phase, :delayed_phase
    config.actions.swap :search, :field_search
    config.field_search.columns = [:enrollment_number, :student, :level, :enrollment_status, :admission_date, :active, :scholarship_durations_active, :professor, :accomplishments, :delayed_phase]

    config.columns[:enrollment_number].search_sql = "enrollments.enrollment_number"
    config.columns[:enrollment_number].search_ui = :text
    config.columns[:student].search_ui = :record_select
    config.columns[:level].search_sql = "levels.id"
    config.columns[:level].search_ui = :select
    config.columns[:enrollment_status].search_sql = "enrollment_statuses.id"
    config.columns[:enrollment_status].search_ui = :select
    config.columns[:admission_date].search_sql = "enrollments.admission_date"
    config.columns[:scholarship_durations_active].search_ui = :select
    config.columns[:scholarship_durations_active].search_sql = ""
    config.columns[:active].search_ui = :select
    config.columns[:active].search_sql = ""
    config.columns[:delayed_phase].search_sql = ""
    config.columns[:delayed_phase].search_ui = :select
    config.columns[:professor].clear_link
    config.columns[:professor].search_sql = "professors.name"
    config.columns[:professor].includes = {:advisements => :professor}
    config.columns[:professor].search_ui = :text
    config.columns[:accomplishments].search_sql = ""

    config.columns[:dismissal].sort_by :sql => 'dismissals.date'
    config.columns[:level].form_ui = :select
    config.columns[:enrollment_status].form_ui = :select
    config.columns[:dismissal].clear_link
    config.columns[:student].clear_link
    config.columns[:level].clear_link
    config.columns[:enrollment_status].clear_link
    config.columns[:admission_date].options = {:format => :monthyear}
#Student can not be configured as record select because it does not allow the user to create a new one, if needed
    config.columns[:student].form_ui = :record_select
    config.create.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
    config.update.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
    config.show.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
  end
  record_select :per_page => 10, :search_on => [:enrollment_number], :order_by => 'enrollment_number', :full_text_search => true

  def self.condition_for_admission_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date1 = Date.new(year.to_i, month.to_i)
      date2 = Date.new(month.to_i==12 ? year.to_i + 1 : year.to_i, (month.to_i % 12) + 1)

      ["DATE(#{column.search_sql}) >= ? and DATE(#{column.search_sql}) < ?", date1, date2]
    end
  end

  def self.condition_for_scholarship_durations_active_column(column, value, like_pattern)
    query_active_scholarships = "select enrollment_id from scholarship_durations where DATE(scholarship_durations.end_date) >= DATE(?) AND  (scholarship_durations.cancel_date is NULL OR DATE(scholarship_durations.cancel_date) >= DATE(?))"
    case value
      when '0' then
        sql = "enrollments.id not in (#{query_active_scholarships})"
      when '1' then
        sql = "enrollments.id in (#{query_active_scholarships})"
      else
        sql = ""
    end

    [sql, Time.now, Time.now]
  end

  def self.condition_for_active_column(column, value, like_pattern)
    query_inactive_enrollment = "select enrollment_id from dismissals where DATE(dismissals.date) <= DATE(?)"
    case value
      when '0' then
        sql = "enrollments.id in (#{query_inactive_enrollment})"
      when '1' then
        sql = "enrollments.id not in (#{query_inactive_enrollment})"
      else
        sql = ""
    end

    [sql, Time.now]
  end

  def self.condition_for_delayed_phase_column(column, value, like_pattern)
    return "" if value[:phase].blank?
    date = value.nil? ? value : Date.parse("#{value[:year]}/#{value[:month]}/#{value[:day]}")
    phase = value[:phase] == "all" ? Phase.all : [Phase.find(value[:phase])]
    enrollments_ids = Enrollment.with_delayed_phases_on(date, phase)
    query_delayed_phase = enrollments_ids.blank? ? "1 = 2" : "enrollments.id in (#{enrollments_ids.join(',')})"
    query_delayed_phase
  end

  def self.condition_for_accomplishments_column(column, value, like_pattern)
    return "" if value[:phase].blank?
    date = value.nil? ? value : Date.parse("#{value[:year]}/#{value[:month]}/#{value[:day]}")
    phase = value[:phase] == "all" ? nil : value[:phase]
    if (value[:phase] == "all")
      enrollments_ids = Enrollment.with_all_phases_accomplished_on(date)
      query = enrollments_ids.blank? ? "1 = 2" : "enrollments.id in (#{enrollments_ids.join(',')})"
    else
      query = "enrollments.id in (select enrollment_id from accomplishments where DATE(conclusion_date) <= DATE('#{date}') and phase_id = #{phase})"
    end
    query
  end


  def to_pdf
    pdf = Prawn::Document.new

    y_position = pdf.cursor

    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [455, y_position],
              :vposition => :top,
              :scale => 0.3
    )

    pdf.font("Courier", :size => 14) do
      pdf.text "Universidade Federal Fluminense
                Instituto de Computação
                Pós-Graduação"
    end

    pdf.move_down 30

    header = [["<b>#{I18n.t("activerecord.attributes.enrollment.student")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.enrollment_number")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.admission_date")}</b>",
               "<b>#{I18n.t("activerecord.attributes.enrollment.dismissal")}</b>"]]
    pdf.table(header, :column_widths => [208, 108, 108, 108],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    each_record_in_page {}
    enrollments_list = find_page(:sorting => active_scaffold_config.list.user.sorting).items

    enrollments = enrollments_list.map do |enrollment|
      [
          enrollment.student[:name],
          enrollment[:enrollment_number],
          enrollment[:admission_date],
          if enrollment.dismissal
            enrollment.dismissal[:date]
          end
      ]
    end

    pdf.table(enrollments, :column_widths => [208, 108, 108, 108],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    send_data(pdf.render, :filename => 'relatorio.pdf', :type => 'application/pdf')
  end


end

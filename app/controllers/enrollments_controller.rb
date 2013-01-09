class EnrollmentsController < ApplicationController
  active_scaffold :enrollment do |config|

    config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal]
    config.list.sorting = {:enrollment_number => 'ASC'}
    config.create.label = :create_enrollment_label
    config.update.label = :update_enrollment_label
#    config.columns[:level].update_columns = :accomplishments
    config.columns[:accomplishments].allow_add_existing = false;

    config.columns << :student
    config.columns.exclude :student
    config.columns << :professor
    config.columns.exclude :professor
    config.columns << :phase
    config.columns.exclude :phase
    config.actions.swap :search, :field_search
    config.field_search.columns = [:enrollment_number, :student, :level, :enrollment_status, :admission_date, :scholarship_durations, :professor, :phase]

    config.columns[:enrollment_number].search_sql = "enrollments.enrollment_number"
    config.columns[:enrollment_number].search_ui = :text
    config.columns[:student].search_ui = :record_select
    config.columns[:level].search_sql = "levels.id"
    config.columns[:level].search_ui = :select
    config.columns[:enrollment_status].search_sql = "enrollment_statuses.id"
    config.columns[:enrollment_status].search_ui = :select
    config.columns[:admission_date].search_sql = "enrollments.admission_date"
    config.columns[:scholarship_durations].search_ui = :select
    config.columns[:professor].clear_link
    config.columns[:professor].search_sql = "professors.name"
    config.columns[:professor].includes = {:advisements => :professor}
    config.columns[:professor].search_ui = :text
    config.columns[:phase].search_sql = "phases.name"
    config.columns[:phase].includes = {:accomplishments => :phase}
    config.columns[:phase].search_ui = :text

    config.columns[:dismissal].sort_by :sql => 'dismissals.date'
    config.columns[:level].form_ui = :select
    config.columns[:enrollment_status].form_ui = :select
    config.columns[:dismissal].clear_link
    config.columns[:student].clear_link
    config.columns[:level].clear_link
    config.columns[:enrollment_status].clear_link
    config.columns[:admission_date].options = {:format => :monthyear}
    #Student can not be configured as record select because it does not allow the user to create a new one, if needed
    #config.columns[:student].form_ui = :record_select        
    config.create.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
    config.update.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
    config.show.columns = [:enrollment_number, :admission_date, :level, :enrollment_status, :obs, :student, :advisements, :accomplishments, :deferrals, :scholarship_durations, :dismissal]
  end
  record_select :per_page => 10, :search_on => [:enrollment_number], :order_by => 'enrollment_number', :full_text_search => true

  def self.condition_for_admission_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty?  ? 1 : value[:year]

    if year != 1
      date1 = Date.new(year.to_i,month.to_i)
      date2 = Date.new(month.to_i==12 ? year.to_i + 1 : year.to_i ,(month.to_i % 12) + 1)

      ["DATE(#{column.search_sql}) >= ? and DATE(#{column.search_sql}) < ?", date1, date2]
    end
  end

  def self.condition_for_scholarship_durations_column(column, value, like_pattern)
    query_active_scholarships = "select enrollment_id from scholarship_durations where DATE(scholarship_durations.end_date) >= DATE(?) OR  DATE(scholarship_durations.cancel_date) >= DATE(?)"
    case value
      when '0' then
        sql = "enrollments.id not in (#{query_active_scholarships})"
      when '1' then
        sql = "enrollments.id in (#{query_active_scholarships})"
      else
        sql = ""
    end

    [sql,Time.now,Time.now]
  end
end
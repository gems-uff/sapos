# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ScholarshipsController < ApplicationController
  authorize_resource

  active_scaffold :scholarship do |config|
    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection, :parameters => {:format => :pdf}

    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search

    config.list.sorting = {:scholarship_number => 'ASC'}
    config.list.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :start_date, :end_date]

    config.columns.add :available
    config.field_search.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :start_date, :end_date, :available]

    config.create.label = :create_scholarship_label

    config.columns[:start_date].search_sql = "scholarships.start_date"
    config.columns[:end_date].search_sql = "scholarships.end_date"
    config.columns[:scholarship_number].search_ui = :text
    config.columns[:available].search_sql = ""
    #config.columns[:available].search_ui = :text


    config.columns[:sponsor].form_ui = :select
    config.columns[:scholarship_type].form_ui = :select
    config.columns[:level].form_ui = :select
    config.columns[:professor].form_ui = :record_select
    config.columns[:scholarship_type].clear_link
    config.columns[:level].clear_link
    config.columns[:sponsor].clear_link

    config.columns[:start_date].options = {:format => :monthyear}
    config.columns[:end_date].options = {:format => :monthyear}


    config.create.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs]
    config.update.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs]
    config.show.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
  end
  record_select :per_page => 10, :search_on => [:scholarship_number], :order_by => 'scholarship_number', :full_text_search => true

  def self.condition_for_available_column(column, value, like_pattern)
    if value[:use] == "yes"
      month = value[:month].empty? ? 1 : value[:month]
      year = value[:year].empty? ? 1 : value[:year]
      
      dt = Date.new(year.to_i, month.to_i)
      #dt = value

      scholarships = Scholarship.arel_table
      scholarship_durations = ScholarshipDuration.arel_table

      allocated_with_end_date = Scholarship.joins(:scholarship_durations)
        .where(scholarship_durations[:end_date].lt(dt)
          .and(scholarship_durations[:cancel_date].eq(nil))
          .and(scholarships[:end_date].eq(nil)
            .or(scholarships[:end_date].gt(Date.today))))
        .collect{ |scholarship| scholarship.id }

      non_allocated = Scholarship.includes(:scholarship_durations)
        .where(scholarship_durations[:scholarship_id].eq(nil)
          .and(scholarships[:end_date].eq(nil)
            .or(scholarships[:end_date].gt(Date.today))))
        .collect{ |scholarship| scholarship.id }

      [scholarships[:id].in(allocated_with_end_date + non_allocated)]
    end
  end

  def self.condition_for_start_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i, month.to_i)

      ["#{column.search_sql.last} >= ?", date]
    end
  end

  def self.condition_for_end_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i, month.to_i)

      ["#{column.search_sql.last} >= ?", date]
    end
  end

  def to_pdf
    each_record_in_page {}
    scholarships_from_page = find_page(:sorting => active_scaffold_config.list.user.sorting).items

    @scholarships = scholarships_from_page.map! do |s|
      [ 
          s[:scholarship_number],
          s.level.nil? ? nil : s.level[:name],
          s.sponsor.nil? ? nil : s.sponsor[:name],
          s.scholarship_type.nil? ? nil : s.scholarship_type[:name],
          s[:start_date].nil? ? nil : I18n.l(s[:start_date], :format => :monthyear),
          s[:end_date].nil? ? nil : I18n.l(s[:end_date], :format => :monthyear)
      ]
    end

    respond_to do |format|
      format.pdf do
        send_data render_to_string, :filename => I18n.t("pdf_content.scholarships.to_pdf.filename"), :type => 'application/pdf'
      end
    end
  end

end 
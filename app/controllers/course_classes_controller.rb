# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseClassesController < ApplicationController
  authorize_resource
  include NumbersHelper
  helper :class_enrollments

  active_scaffold :course_class do |config|

    config.columns.add :class_enrollments_count

    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :course, :professor, :year, :semester, :class_enrollments_count]
    config.create.label = :create_course_class_label
    config.update.label = :update_course_class_label

    config.actions.swap :search, :field_search
    config.field_search.columns = [:name, :year, :semester, :professor, :course, :enrollments]

    config.columns[:professor].search_sql = "professors.name"
    config.columns[:professor].search_ui = :text
    config.columns[:course].search_sql = "courses.name"
    config.columns[:course].search_ui = :text
    config.columns[:name].search_ui = :text
    config.columns[:enrollments].search_ui = :record_select

    config.action_links.add 'summary_pdf', :label => I18n.t('pdf_content.course_class.summary.link'), :page => true, :type => :member, :parameters => {:format => :pdf}

    config.columns[:course].form_ui = :record_select
    config.columns[:professor].form_ui = :record_select
    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {:options => ['1', '2']}
    config.columns[:year].options = {:options => ((Date.today.year-5)..Date.today.year).map { |y| y }.reverse}

    config.create.columns =
        [:name, :course, :professor, :year, :semester, :allocations]

    config.update.columns =
        [:name, :course, :professor, :year, :semester, :class_enrollments, :allocations]
  end
  record_select :per_page => 10, :order_by => 'name', :full_text_search => true


  def summary_pdf
    @course_class = CourseClass.find(params[:id])
    course_class = @course_class

    respond_to do |format|
      format.pdf do
        send_data render_to_string, :filename => "#{I18n.t('pdf_content.course_class.summary.title')} -  #{course_class.name || course_class.course.name}.pdf", :type => 'application/pdf'
      end
    end
  end


end 

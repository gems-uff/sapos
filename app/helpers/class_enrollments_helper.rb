# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ClassEnrollmentsHelper
  def grade_form_column(record, options)
    options = options.merge({:maxlength => 5, :class => "grade-input numeric-input text-input"})
    text_field :record, :grade_to_view, options
  end

  def course_class_year_semester_search_column(record, options)


  	html = select_tag(
  		"#{options[:name]}[course]", 
  		options_for_select(Course.all.collect{|c| [c.name, c.id]}),
  		:prompt => as_(:_select_),
  		:id => "#{options[:id]}_course",
  		:class => "as_search_search_course_class_option"
  	)

  	html << label_tag(
  		"#{options[:id]}_year_semester",
  		I18n.t("activerecord.attributes.enrollment.year_semester_label"),
  		:style => "margin: 0 15px;"
  	)

  	html << select_tag(
  		"#{options[:name]}[year]", 
  		options_for_select(CourseClass.group(:year).select(:year).collect{|y| y[:year]}),
  		:include_blank => as_(:_select_),
  		:id => "#{options[:id]}_year",
  		:class => "as_search_search_course_class_option"
  	)

	html << select_tag(
  		"#{options[:name]}[semester]", 
  		options_for_select(CourseClass.group(:semester).select(:semester).collect{|y| y[:semester]}),
  		:include_blank => as_(:_select_),
  		:id => "#{options[:id]}_semester",
  		:class => "as_search_search_course_class_option"
  	)

  	#select :record, "id", options_for_select(CourseClass.group(:semester).select(:semester).collect{|y| y[:semester]}), {:include_blank => as_('- select -')}, options
  	content_tag :span, html, :class => 'search_course_class'
  end
end
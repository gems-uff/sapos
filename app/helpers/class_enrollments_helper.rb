# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ClassEnrollmentsHelper
  def grade_form_column(record, options)
    options = options.merge({:maxlength => 5, :class => "grade-input numeric-input text-input"})
    text_field :record, :grade_to_view, options
  end

  def course_class_year_semester_search_column(record, options)

  	disciplinas_filtro = Course.all.collect{|c| [I18n.transliterate(c.name.squish.downcase), c.name, c.id]}
  	disciplinas_filtro.sort_by!{ |elemento| elemento[0] }

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

  def course_class_form_column(record, options)
    logger.info "  RecordSelect Helper ClassEnrollmentsHelper\\course_class_form_column"
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR 
    record_select_field :course_class, record.course_class || CourseClass.new, options.merge!(class: "text-input")
  end

  def enrollment_form_column(record, options)
    logger.info "  RecordSelect Helper ClassEnrollmentsHelper\\enrollment_form_column"
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR
    options.merge!(style: "width:320px; background-image:none !important; color:#000000 !important;")
    record_select_field :enrollment, record.enrollment || Enrollment.new, options.merge!(class: "text-input")
  end

  def disapproved_by_absence_form_column(record, options)
	  options = options.merge({:class_enrollments_id => "#{record.id}", :grade_of_disapproval_for_absence => "#{CustomVariable.grade_of_disapproval_for_absence.nil? ? nil : CustomVariable.grade_of_disapproval_for_absence.to_f/10.0}", :course_has_grade => "#{record.course_has_grade}"})
    if record.course_has_grade
      grade_of_disapproval_for_absence = ((!CustomVariable.grade_of_disapproval_for_absence)||(CustomVariable.grade_of_disapproval_for_absence.nil?)) ? nil : CustomVariable.grade_of_disapproval_for_absence.to_f/10.0
      options = options.merge(onchange: "if( (this.checked) && (document.getElementById('record_grade_#{record.course_class_id}_class_enrollments_#{record.id}').value.trim() == '')){document.getElementById('record_grade_#{record.course_class_id}_class_enrollments_#{record.id}').value = '#{grade_of_disapproval_for_absence}';}")
    end
    check_box :record, :disapproved_by_absence_to_view, options
  end

  def grade_not_count_in_gpr_form_column(record, options)

    justification_size = "30"
    justification_label = I18n.t("helpers.class_enrollments.justification_grade_not_count_in_gpr")

    if controller_name != "class_enrollments"
      justification_size = "8"
      justification_label = justification_label.strip 
    end

    html = check_box :record, :grade_not_count_in_gpr, options.merge({:style => "margin: 0px 0px 0px 8px;"})
    html = ActiveSupport::SafeBuffer.new("<span style='display:inline-block;vertical-align:middle;'>") + html + ActiveSupport::SafeBuffer.new("</span>")

    html << label_tag("", justification_label, :style => "margin: 0 8px;")  

    html << text_field_tag( "record[justification_grade_not_count_in_gpr]", record.justification_grade_not_count_in_gpr, :class => "text-input", :autocomplete => "off", :maxlength => "255", :size => justification_size, :name => options[:name].sub("grade_not_count_in_gpr","justification_grade_not_count_in_gpr"))

    html

  end

  def obs_form_column(record, options)
    extra_options = {}

    if controller_name == "course_classes"
      extra_options ={:cols => "6"}
    end

    text_area(:record, :obs, options.merge(extra_options))
  end

  def justification_grade_not_count_in_gpr_form_column(record, options)
    return ""
  end

end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ClassEnrollmentHelperConcern
  def custom_enrollment_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    options[:style] = "width:320px; background-image:none !important;
                       color:#000000 !important;"
    record_select_field(
      :enrollment, record.enrollment || Enrollment.new, options
    )
  end

  def custom_course_class_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    record_select_field(
      :course_class, record.course_class || CourseClass.new, options
    )
  end

  def custom_disapproved_by_absence_form_column(record, options)
    options = options.merge({
      class_enrollments_id: "#{record.id}",
      grade_of_disapproval_for_absence: "#{
        CustomVariable.grade_of_disapproval_for_absence.nil? ?
          nil : CustomVariable.grade_of_disapproval_for_absence.to_f / 10.0
      }",
      course_has_grade: "#{record.course_has_grade}",
      overwrite_confirm_msg: I18n.t("activerecord.attributes.class_enrollment.confirm_grade_overwrite"),
      data_disapproved: ClassEnrollment::DISAPPROVED
    })
    check_box(:record, :disapproved_by_absence_to_view, options)
  end

  def custom_grade_form_column(record, options)
    return "" if !record.course_has_grade
    options = options.merge({
      maxlength: 5, class: "grade-input numeric-input text-input",
      data_approved: ClassEnrollment::APPROVED,
      data_disapproved: ClassEnrollment::DISAPPROVED,
      grade_placeholder: I18n.t("activerecord.attributes.class_enrollment.placeholder_grade"),
      minimum_grade_for_approval: (CustomVariable.minimum_grade_for_approval.to_f / 10.0)
    })
    text_field(:record, :grade_to_view, options)
  end

  def custom_grade_not_count_in_gpr_form_column(record, options)
    justification_size = "30"
    justification_label = I18n.t(
      "helpers.class_enrollments.justification_grade_not_count_in_gpr"
    )

    if controller_name != "class_enrollments"
      justification_size = "8"
      justification_label = justification_label.strip
    end

    html = check_box :record, :grade_not_count_in_gpr, options.merge({
      style: "margin: 0px 0px 0px 8px;"
    })
    html = ActiveSupport::SafeBuffer.new(
      "<span style='display:inline-block;vertical-align:middle;'>"
    ) + html + ActiveSupport::SafeBuffer.new("</span>")

    html << label_tag("", justification_label, style: "margin: 0 8px;")

    html << text_field_tag(
      "record[justification_grade_not_count_in_gpr]",
      record.justification_grade_not_count_in_gpr,
      class: "text-input", autocomplete: "off", maxlength: "255",
      size: justification_size, name: options[:name].sub(
        "grade_not_count_in_gpr",
        "justification_grade_not_count_in_gpr"
      )
    )

    html
  end

  def custom_obs_form_column(record, options)
    extra_options = {}

    if controller_name == "course_classes"
      extra_options = { cols: "6" }
    end

    text_area(:record, :obs, options.merge(extra_options))
  end

  def custom_justification_grade_not_count_in_gpr_form_column(record, options)
    ""
  end

  def custom_field_attributes(column, record)
    return { style: "padding-left: 10px;" } if (column.name == :obs) && (
      controller_name != "class_enrollments"
    )

    return if column.name != :grade_not_count_in_gpr
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      return { style: "display:none;" }
    end
    { style: "width: 190px;" } if controller_name != "class_enrollments"
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ClassEnrollmentDrop < ActiveRecordAttributesDrop
  define_drop_relationship :enrollment, EnrollmentDrop
  define_drop_relationship :course_class, CourseClassDrop
  define_drop_accessor :grade_to_view

  def absence_to_view
    ((@record.attendance_to_label == "I") ? I18n.t('active_scaffold.true') : I18n.t('active_scaffold.false'))
  end

  def full_absence_to_view
    if @record.attendance_to_label == "I"
      I18n.t("activerecord.attributes.class_enrollment.disapproved_by_absence")
    else
      "#{I18n.t("active_scaffold.false")} #{I18n.t("activerecord.attributes.class_enrollment.disapproved_by_absence")}"
    end
  end

  def absence_changed
    @record.will_save_change_to_disapproved_by_absence? ? '*' : ''
  end

  def situation_changed
    @record.will_save_change_to_situation? ? '*' : ''
  end

  def grade_changed
    @record.will_save_change_to_grade? ? '*' : ''
  end
end

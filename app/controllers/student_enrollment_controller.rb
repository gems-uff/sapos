# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentEnrollmentController < ApplicationController
  include LandingHelper
  helper :course_classes
  skip_authorization_check

  def _valid_enrollment
    raise CanCan::AccessDenied.new if current_user.nil?
    raise CanCan::AccessDenied.new if current_user.student.nil?
    set_sidebar
    @enrollment = Enrollment.find_by(enrollment_number: params[:id])
    ! (@enrollment.nil? || @enrollment.student.user != current_user || ! @enrollment.enrollment_status.user)
  end

  def redirect_alert(message, url)
    flash[:notice] = message
    redirect_to url
  end

  def show
    return redirect_alert("Matrícula inválida", landing_url) if ! _valid_enrollment
    @partials = []
    if @enrollment.dismissal.nil?
      now = Time.now
      open_semester = ClassSchedule.find_by(
        ClassSchedule.arel_table[:enrollment_start].lteq(now),
        ClassSchedule.arel_table[:enrollment_end].gteq(now),
      )
      unless open_semester.nil?
        @partials << ['student_enrollment/show_enroll', {semester: open_semester}]
      end
    end
    render :show
  end

  def enroll
    return redirect_alert("Matrícula inválida", landing_url) if ! _valid_enrollment
    return redirect_alert("Matrícula desligada", student_enrollment_path(@enrollment.enrollment_number)) if ! @enrollment.dismissal.nil?
    now = Time.now
    @semester = ClassSchedule.find_by(
      ClassSchedule.arel_table[:enrollment_start].lteq(now),
      ClassSchedule.arel_table[:enrollment_end].gteq(now),
      ClassSchedule.arel_table[:year].gteq(params[:year]),
      ClassSchedule.arel_table[:semester].gteq(params[:semester])
    )
    return redirect_alert("Semestre inválido", student_enrollment_path(@enrollment.enrollment_number)) if @semester.nil?
    @available_classes = CourseClass.where(
      year: @semester.year,
      semester: @semester.semester,
    )
    render :enroll
  end

end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentEnrollmentController < ApplicationController
  include LandingHelper
  helper :course_classes
  skip_authorization_check

  def show
    return unless _valid_enrollment.nil?
    @partials = []
    if @enrollment.dismissal.nil?
      now = Time.now
      open_semester = ClassSchedule.find_by(
        ClassSchedule.arel_table[:enrollment_start].lteq(now),
        ClassSchedule.arel_table[:enrollment_end].gteq(now),
      )
      unless open_semester.nil?
        enrollment_request = EnrollmentRequest.find_or_initialize_by(
          enrollment: @enrollment,
          year: open_semester.year,
          semester: open_semester.semester
        )
        @partials << ['student_enrollment/show_enroll', {semester: open_semester, enrollment_request: enrollment_request}]
      end
    end
    render :show
  end

  def enroll
    return unless _prepare_enroll.nil?
    render :enroll
  end

  def save_enroll
    return unless _prepare_enroll.nil?
    @enrollment_request.assign_course_class_ids(enrollment_request_params[:course_class_ids])
    @enrollment_request.status = ClassEnrollmentRequest::REQUESTED
    @enrollment_request.last_student_change_at = Time.current
    if enrollment_request_params[:delete_request] == "1"
      @enrollment_request.destroy!
      redirect_to student_enrollment_path(@enrollment.enrollment_number), notice: I18n.t("student_enrollment.notice.request_removed")
    elsif @enrollment_request.valid? && @enrollment_request.save
      redirect_to student_enrollment_path(@enrollment.enrollment_number), notice: I18n.t("student_enrollment.notice.request_saved")
    else
      render :enroll
    end
  end

  private

  def _valid_enrollment
    raise CanCan::AccessDenied.new if current_user.nil?
    raise CanCan::AccessDenied.new if current_user.student.nil?
    set_sidebar
    @enrollment = Enrollment.find_by(enrollment_number: params[:id])
    if (@enrollment.nil? || @enrollment.student.user != current_user || ! @enrollment.enrollment_status.user)
      return redirect_to landing_url, alert: I18n.t("student_enrollment.alert.invalid_enrollment", enrollment: params[:id])
    end
    nil
  end

  def _redirect_semester
    redirect = _valid_enrollment
    return redirect unless redirect.nil?
    if @enrollment.dismissal.present?
      return redirect_to student_enrollment_path(@enrollment.enrollment_number), alert: I18n.t("student_enrollment.alert.dismissed_enrollment", enrollment: params[:id])
    end
    now = Time.now
    @semester = ClassSchedule.find_by(
      ClassSchedule.arel_table[:enrollment_start].lteq(now)
        .and(ClassSchedule.arel_table[:enrollment_end].gteq(now))
        .and(ClassSchedule.arel_table[:year].eq(params[:year]))
        .and(ClassSchedule.arel_table[:semester].eq(params[:semester]))
    )
    if @semester.nil?
      return redirect_to student_enrollment_path(@enrollment.enrollment_number), alert: I18n.t("student_enrollment.alert.invalid_semester", year: params[:year], semester: params[:semester])
    end
    nil
  end

  def _prepare_enroll
    redirect = _redirect_semester
    return redirect unless redirect.nil?
    @available_classes = CourseClass.where(
      year: @semester.year,
      semester: @semester.semester,
    )
    @enrollment_request = EnrollmentRequest.find_or_initialize_by(
      enrollment: @enrollment,
      year: @semester.year,
      semester: @semester.semester
    )
    nil
  end

  def enrollment_request_params
    params.require(:enrollment_request).permit(:delete_request, course_class_ids: [])
  end 

end

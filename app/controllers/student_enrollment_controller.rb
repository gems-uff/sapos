# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentEnrollmentController < ApplicationController
  include LandingHelper
  helper :course_classes
  skip_authorization_check

  def show
    return unless _valid_enrollment.nil?
    @partials = []

    @partials << ['student_enrollment/show_info', { enrollment: @enrollment }]

    if @enrollment.dismissal.nil?
      now = Time.now
      open_semester = ClassSchedule.find_by(ClassSchedule.arel_enroll_open?)
      unless open_semester.nil?
        enrollment_request = EnrollmentRequest.find_or_initialize_by(
          enrollment: @enrollment,
          year: open_semester.year,
          semester: open_semester.semester
        )
        @partials << ['student_enrollment/show_enroll', { semester: open_semester, enrollment_request: enrollment_request }]
      end
    else
      @partials << ['student_enrollment/show_dismissal', { 
        enrollment: @enrollment,
        dismissal: @enrollment.dismissal,
        thesis_defense_committee_professors: @enrollment.thesis_defense_committee_professors
      }]

    end

    unless @enrollment.class_enrollments.empty?
      @partials << ['student_enrollment/show_class_enrollments', { class_enrollments: @enrollment.class_enrollments }]
    end


    unless @enrollment.advisements.empty?
      @partials << ['student_enrollment/show_advisements', { advisements: @enrollment.advisements }]
    end

    unless @enrollment.phase_completions.empty?
      @partials << ['student_enrollment/show_phases', { phase_completions: @enrollment.phase_completions }]
    end

    unless @enrollment.deferrals.empty?
      @partials << ['student_enrollment/show_deferrals', { deferrals: @enrollment.deferrals }]
    end

    unless @enrollment.enrollment_holds.empty?
      @partials << ['student_enrollment/show_holds', { holds: @enrollment.enrollment_holds }]
    end

    unless @enrollment.scholarship_durations.empty?
      @partials << ['student_enrollment/show_scholarships', { scholarship_durations: @enrollment.scholarship_durations }]
    end

    render :show
  end

  def enroll
    return unless _prepare_enroll(false).nil?
    render :enroll
  end

  def save_enroll
    return unless _prepare_enroll(true).nil?
    message = enrollment_request_params[:message]
    changed, remove_class_enrollments = @enrollment_request.assign_course_class_ids(
      enrollment_request_params[:course_class_ids],
      @semester
    )
    changed ||= ! message.empty?
    if changed
      unless message.empty?
        @comment = @enrollment_request.enrollment_request_comments.build(message: message, user: current_user)
      end
      @enrollment_request.status = ClassEnrollmentRequest::REQUESTED
      @enrollment_request.last_student_change_at = Time.current
      @enrollment_request.student_view_at = @enrollment_request.last_student_change_at 
      
      emails = [EmailTemplate.load_template("student_enrollments:email_to_student").prepare_message({
        :record => @enrollment_request
      })]
      @enrollment_request.enrollment.advisements.each do |advisement|
        emails << EmailTemplate.load_template("student_enrollments:email_to_advisor").prepare_message({
          :record => @enrollment_request,
          :advisement => advisement
        })
      end
      Notifier.send_emails(notifications: emails)
      
    end
    if enrollment_request_params[:delete_request] == "1"
      @enrollment_request.destroy!
      redirect_to student_enrollment_path(@enrollment.enrollment_number), notice: I18n.t("student_enrollment.notice.request_removed")
    elsif @enrollment_request.valid_request?(remove_class_enrollments)
      @enrollment_request.save_request(remove_class_enrollments)
      redirect_to student_enrollment_path(@enrollment.enrollment_number), notice: I18n.t("student_enrollment.notice.request_saved")
    else
      @enrollment_request.enrollment_request_comments.delete(@comment) if ! @comment.nil? && ! @comment.persisted?
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

  def _redirect_semester(check_time)
    redirect = _valid_enrollment
    return redirect unless redirect.nil?
    if @enrollment.dismissal.present?
      return redirect_to student_enrollment_path(@enrollment.enrollment_number), alert: I18n.t("student_enrollment.alert.dismissed_enrollment", enrollment: params[:id])
    end
    @semester = ClassSchedule.find_by(
      ClassSchedule.arel_table[:year].eq(params[:year])
      .and(ClassSchedule.arel_table[:semester].eq(params[:semester]))
    )
    if @semester.nil?
      return redirect_to student_enrollment_path(@enrollment.enrollment_number), alert: I18n.t("student_enrollment.alert.invalid_semester", year: params[:year], semester: params[:semester])
    end
    if check_time && ! @semester.enroll_open?
      return redirect_to student_enrollment_path(@enrollment.enrollment_number), alert: I18n.t("student_enrollment.alert.closed_enrollment", year: params[:year], semester: params[:semester])
    end
    nil
  end

  def _prepare_enroll(check_time)
    redirect = _redirect_semester(check_time)
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
    if @enrollment_request.persisted?
      @last_read = @enrollment_request.last_student_read_time
      @enrollment_request.student_view_at = Time.current
      @enrollment_request.save
    end
    nil
  end

  def enrollment_request_params
    params.require(:enrollment_request).permit(:delete_request, :message, course_class_ids: [])
  end 

end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentEnrollmentController < ApplicationController
  helper :course_classes
  authorize_resource class: false

  
  def show
    return unless _valid_enrollment.nil?

    @partials = [['student_enrollment/show_info', { enrollment: @enrollment }]]

    if @enrollment.dismissal.blank?
      existing_partial('student_enrollment/show_enroll', :semester, ClassSchedule.find_by(ClassSchedule.arel_enroll_open?)) do |semester|
        enrollment_request = EnrollmentRequest.find_or_initialize_by(enrollment: @enrollment, year: semester.year, semester: semester.semester)
        { enrollment_request: enrollment_request }
      end
    end

    existing_partial('student_enrollment/show_dismissal', :dismissal, @enrollment.dismissal,
                        enrollment: @enrollment, thesis_defense_committee_professors: @enrollment.thesis_defense_committee_professors)
    existing_partial('student_enrollment/show_class_enrollments', :class_enrollments, @enrollment.class_enrollments)
    existing_partial('student_enrollment/show_advisements', :advisements, @enrollment.advisements)
    existing_partial('student_enrollment/show_phases', :phase_completions, @enrollment.phase_completions)
    existing_partial('student_enrollment/show_deferrals', :deferrals, @enrollment.deferrals)
    existing_partial('student_enrollment/show_holds', :holds, @enrollment.enrollment_holds)
    existing_partial('student_enrollment/show_scholarships', :scholarship_durations, @enrollment.scholarship_durations)
    
    render :show
  end

  def enroll
    return unless _prepare_enroll(false).nil?
    render :enroll
  end

  def save_enroll
    return unless _prepare_enroll(true).nil?
    if enrollment_request_params[:delete_request] == "1"
      return if delete_enrollment_request_and_redirect
    else
      return if save_enrollment_request_and_redirect
    end
    render :enroll
  end

  private

  def _valid_enrollment
    @enrollment = Enrollment.find(params[:id])
    if (@enrollment.blank? || @enrollment.student.user != current_user || !@enrollment.enrollment_status.user)
      raise CanCan::AccessDenied.new
    end
    nil
  end

  def _redirect_semester(check_time)
    redirect = _valid_enrollment
    return redirect unless redirect.nil?
    if @enrollment.dismissal.present?
      return redirect_to student_enrollment_path(@enrollment.id), alert: I18n.t("student_enrollment.alert.dismissed_enrollment", enrollment: params[:id])
    end
    @semester = ClassSchedule.find_by(
      ClassSchedule.arel_table[:year].eq(params[:year])
      .and(ClassSchedule.arel_table[:semester].eq(params[:semester]))
    )
    if @semester.nil?
      raise CanCan::AccessDenied.new
    end
    if check_time && ! @semester.enroll_open?
      return redirect_to student_enrollment_path(@enrollment.id), alert: I18n.t("student_enrollment.alert.closed_enrollment", year: params[:year], semester: params[:semester])
    end
    nil
  end

  def _prepare_enroll(check_time)
    redirect = _redirect_semester(check_time)
    return redirect unless redirect.nil?
    @available_classes = CourseClass.where(
      year: @semester.year,
      semester: @semester.semester,
    ).includes(:allocations)
     .includes(course: [ :course_type ])
     .includes(:professor)
    @on_demand = Course.includes(:course_type).where(course_types: { on_demand: true })
    @advisement_authorizations = Professor.joins(:advisement_authorizations).order(:name).distinct
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
    params.require(:enrollment_request).permit(:delete_request, :message, course_class_ids: [], course_ids: [:selected, :professor] )
  end

  def existing_partial(partial, attribute, association, others={})
    return if association.blank?
    
    extra = yield association if block_given?
    extra ||= {}
    @partials << [partial, { attribute => association }.merge(others).merge(extra)]
  end

  def delete_enrollment_request_and_redirect
    is_requesting = @enrollment_request.has_effected_class_enrollment?
    if @enrollment_request.destroy_request(@semester)
      attributes = { record: @enrollment_request, requesting: is_requesting }
      emails = [EmailTemplate.load_template("student_enrollments:removal_email_to_student").prepare_message(attributes)]
      @enrollment_request.enrollment.advisements.each do |advisement|
        emails << EmailTemplate.load_template("student_enrollments:removal_email_to_advisor")
                              .prepare_message(attributes.merge({ advisement: advisement }))
      end
      Notifier.send_emails(notifications: emails)
      return redirect_to student_enrollment_path(@enrollment.id), notice: (
        is_requesting ? 
          I18n.t("student_enrollment.notice.removal_requested") :
          I18n.t("student_enrollment.notice.request_removed")
      )
    end
    false
  end

  def save_enrollment_request_and_redirect
    message = enrollment_request_params[:message]
    request_change = @enrollment_request.assign_course_class_ids(prepare_course_class_ids, @semester)
    changed = request_change[:new_removal_requests].any? || 
      request_change[:new_insertion_requests].any? ||
      request_change[:remove_removal_requests].any? ||
      request_change[:remove_insertion_requests].any?
    changed ||= message.present?
    if changed
      @comment = @enrollment_request.enrollment_request_comments.build(message: message, user: current_user) unless message.empty?
      @enrollment_request.student_change!
    end
    if @enrollment_request.save_request
      notify_enrollment_request_change(@enrollment_request, request_change) if changed
      return redirect_to student_enrollment_path(@enrollment.id), notice: I18n.t("student_enrollment.notice.request_saved")
    end
    @enrollment_request.enrollment_request_comments.delete(@comment) if ! @comment.nil? && ! @comment.persisted?
    false
  end

  def find_or_create_course_class_in_this_semester(course_id, professor_id)
    attributes = {
      course_id: course_id, professor_id: professor_id,
      year: @semester.year, semester: @semester.semester
    }
    course_class = CourseClass.find_by(attributes)
    return course_class if course_class.present?

    course = Course.find(course_id)
    course_class = CourseClass.create(attributes.merge({ name: course.name })) if course.present?
    course_class
  end

  def prepare_course_class_ids
    course_class_ids = enrollment_request_params[:course_class_ids] || []
    on_demand_course_ids = enrollment_request_params[:course_ids] || []

    on_demand_course_ids.each do |course_id, data|
      next if data[:selected] != "1"
      
      course_class = find_or_create_course_class_in_this_semester(course_id.to_i, data[:professor].to_i)
      course_class_ids << course_class.id.to_s if course_class.present?
    end
    course_class_ids.uniq
  end

  def notify_enrollment_request_change(enrollment_request, request_change)
    attributes = { record: enrollment_request }.merge(request_change)
    emails = [EmailTemplate.load_template("student_enrollments:email_to_student").prepare_message(attributes)]
    enrollment_request.enrollment.advisements.each do |advisement|
      emails << EmailTemplate.load_template("student_enrollments:email_to_advisor")
                             .prepare_message(attributes.merge({ advisement: advisement }))
    end
    Notifier.send_emails(notifications: emails)
  end

end

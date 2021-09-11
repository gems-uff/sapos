# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class LandingController < ApplicationController
  include LandingHelper
  skip_authorization_check

  def index
    raise CanCan::AccessDenied.new if current_user.nil?


    unless current_user.student.nil?
      enrollments = current_user.student.enrollments.order(admission_date: :desc)
      max_enrollment = enrollments.each_with_index.max_by do |enrolmment, index|
        [
          (enrolmment.enrollment_status.user && 1 || 0),  # status allows user
          (enrolmment.dismissal.nil? && 1 || 0),  # was not dismissed
          -index # last admission first
        ]
      end
      if ! max_enrollment.nil? && max_enrollment[0].enrollment_status.user
        return redirect_to student_enrollment_path(max_enrollment[0].id)
      end
    else
      return redirect_to pendencies_path
    end
    set_sidebar
    render :index
  end

end

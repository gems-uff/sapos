# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StudentEnrollmentController < ApplicationController
  include LandingHelper
  skip_authorization_check

  def show
    raise CanCan::AccessDenied.new if current_user.nil?
    raise CanCan::AccessDenied.new if current_user.student.nil?
    set_sidebar
    @enrollment = Enrollment.find_by(enrollment_number: params[:id])
    if @enrollment.nil? || @enrollment.student.user != current_user || ! @enrollment.enrollment_status.user
      redirect_to landing_url
    else
      render :show
    end
  end


end

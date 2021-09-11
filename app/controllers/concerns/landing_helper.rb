# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module LandingHelper extend ActiveSupport::Concern

  def set_sidebar
    @emptylanding = true
    @landingsidebar = Proc.new do |land|
      unless current_user.nil? || current_user.student.nil?
        enrollments = current_user.student.enrollments.order(admission_date: :desc)
        enrollments.each do |enrollment|
          if enrollment.enrollment_status.user
            number = enrollment.enrollment_number
            path = student_enrollment_path(enrollment.id)
            land.item number, number, path, :if => Proc.new { can?(:read, :landing) }
            @emptylanding = false
          end
        end
      end
      if @emptylanding
        land.item :landing, 'Principal', landing_url, :if => Proc.new { can?(:read, :landing) }
      end
    end

  end

end

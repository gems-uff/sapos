# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  check_authorization unless: :devise_controller?

  skip_authorization_check only: [:root, :route_not_found]

  before_action :authenticate_user!
  before_action :parse_date
  before_action :set_paper_trail_whodunnit
  before_action :set_landing
  before_action :prepare_exception_notifier
  before_action :prepare_background

  clear_helpers

  # Defines which controller and action should be shown when the base
  # URL is acessed (root route in routes.rb).
  def root
    if can? :read, :landing
      return if redirect_to(controller: "landing", action: "index")
    end
    [
      Enrollment, Professor, ScholarshipDuration,
      Phase, Course, City, User, Student
    ].each do |model|
      if can? :read, model
        return if redirect_to(
          controller: model.name.underscore.pluralize.downcase, action: "index"
        )
      end
    end
  end

  private
    def prepare_background
      @simple_view = params[:simple_view].present?
      @show_background = user_signed_in?
    end

    def prepare_exception_notifier
      request.env["exception_notifier.exception_data"] = {
        user_id: current_user&.id,
        user_name: current_user&.name,
        user_email: current_user&.email,
        url: request.original_url,
      }
    end

    def set_landing
      @landingsidebar = Proc.new do |land|
        student_landing_menu(land)
      end
    end

    def student_landing_menu(land)
      return if current_user.blank? || current_user.student.blank?

      @emptylanding = true
      enrollments = current_user.student.enrollments.order(admission_date: :desc)
      enrollments.each do |enrollment|
        if enrollment.enrollment_status.user
          number = enrollment.enrollment_number
          path = student_enrollment_path(enrollment.id)
          land.item number, number, path,
            if: Proc.new { can?(:show, :student_enrollment) }
          @emptylanding = false
        end
      end

      if @emptylanding
        land.item :landing, "Principal", landing_url,
          if: Proc.new { can?(:read, :landing) }
      end
    end

    # def authenticate
    #   redirect_to login_url unless User.find_by_id(session[:user_id])
    # end

    # This application has custom values for date inputs,
    # having month and year as default for most dates
    # here we nullify invalid dates that comes from the request
    # invalid dates consists in dates with year < 1000
    def parse_date
      if params[:record]
        external_key = ""
        invalid_year = false
        params[:record].dup.each { |key, value|
          if key.include?("1i")
            invalid_year = value.to_i < 1000
            external_key = key.split("(")[0]
          end

          if invalid_year
            invalid_year = false
            params[:record].delete_if { |key, value|
              key.include?(external_key)
            }

            params[:record][external_key] = params[:record].delete(external_key)
          end
        }
      end
    end
end

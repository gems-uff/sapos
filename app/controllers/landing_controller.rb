# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class LandingController < ApplicationController
  authorize_resource class: false

  def index
    raise CanCan::AccessDenied.new if current_user.nil?

    unless current_user.actual_role != Role::ROLE_ALUNO
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
      return redirect_to pendencies_path if can? :read, :pendency
    end
    render :index
  end

  def download
    medium_hash = params[:hash]
    if medium_hash.nil?
      medium_hash = params[:medium_hash]
      medium_hash = "#{medium_hash}.#{params[:format]}" if params[:format].present?
    end
    record = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.where(
      medium_hash: medium_hash
    ).first
    if record.blank?
      raise ActionController::RoutingError.new("Não encontrado")
    end
    send_data(record.read, filename: record.original_filename, disposition: :inline)
  end
end

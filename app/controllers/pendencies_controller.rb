# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PendenciesController < ApplicationController
  skip_authorization_check

  def index
    raise CanCan::AccessDenied.new if current_user.nil?
    raise CanCan::AccessDenied.new if current_user.role_id == 
    @landingsidebar = Proc.new do |land|
      land.item :pendencies, 'Pendências', pendencies_url, :if => Proc.new { can?(:read, :landing) }
    end
    @partials = []
    
    pendency_condition = EnrollmentRequest.pendency_condition
    requests = EnrollmentRequest.where(pendency_condition)
    unless requests.empty?
      @partials << ['pendencies/enrollment_requests', {conditions: pendency_condition}]
    end

    class_pendency_condition = ClassEnrollmentRequest.pendency_condition
    class_requests = ClassEnrollmentRequest.where(class_pendency_condition)
    unless class_requests.empty?
      @partials << ['pendencies/class_enrollment_requests', {conditions: class_pendency_condition}]
    end

    render :index
  end


end

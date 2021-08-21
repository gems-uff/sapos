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

    render :index
  end


end

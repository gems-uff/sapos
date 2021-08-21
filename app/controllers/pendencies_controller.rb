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

    @partials << ['pendencies/enrollment_requests', {conditions: []}] # ToDo constrains: https://github.com/activescaffold/active_scaffold/wiki/Embedded-Scaffolds


    render :index
  end


end

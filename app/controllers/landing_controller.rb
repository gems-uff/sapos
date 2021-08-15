# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class LandingController < ApplicationController
  skip_authorization_check

  def index
    @landingsidebar = Proc.new do |land|
      land.item :landing, 'Principal', landing_url, :if => Proc.new { can?(:read, :landing) }
    end
    render :index
  end


end

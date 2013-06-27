# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhaseDurationsController < ApplicationController
  authorize_resource

  active_scaffold :phase_duration do |conf|
  end

end 
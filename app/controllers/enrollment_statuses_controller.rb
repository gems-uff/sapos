# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentStatusesController < ApplicationController
  authorize_resource

  active_scaffold :enrollment_status do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_enrollment_status_label
    columns = [:name]
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns
  end

end
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentStatusesController < ApplicationController
  active_scaffold :enrollment_status do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_enrollment_status_label
  end

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end
end 
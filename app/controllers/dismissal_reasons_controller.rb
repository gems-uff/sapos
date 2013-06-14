# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DismissalReasonsController < ApplicationController
  active_scaffold :dismissal_reason do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_dismissal_reason_label
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
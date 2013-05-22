class LevelsController < ApplicationController
  active_scaffold :level do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_level_label
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
class SponsorsController < ApplicationController
  active_scaffold :sponsor do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_sponsor_label
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
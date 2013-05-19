class CitiesController < ApplicationController
  active_scaffold :city do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :state]
    config.create.label = :create_city_label
    config.columns[:state].form_ui = :select
    config.columns[:state].clear_link
    config.create.columns = [:state, :name]
    config.update.label = :update_city_label
    config.update.columns = [:state, :name]
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
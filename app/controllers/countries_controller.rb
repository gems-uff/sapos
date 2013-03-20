class CountriesController < ApplicationController
  active_scaffold :country do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name]
    config.create.label = :create_country_label
    config.create.columns = [:name]
    config.update.label = :update_country_label
    config.update.columns = [:name]
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
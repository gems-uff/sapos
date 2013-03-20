class RolesController < ApplicationController
  active_scaffold :role do |config|
    config.list.columns = [:id, :name, :description]
    config.columns = [:name, :description]
    config.columns[:description].form_ui = :textarea
    config.show.link = false
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
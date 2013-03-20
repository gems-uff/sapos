class InstitutionsController < ApplicationController
  active_scaffold :institution do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code]
    config.create.label = :create_institution_label
    config.columns = [:name, :code, :courses]
    config.columns[:courses].associated_limit = nil
    config.columns[:courses].form_ui = :record_select
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

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
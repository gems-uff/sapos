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
end 
class InstitutionsController < ApplicationController
  active_scaffold :institution do |config|    
    config.list.sorting = {:name => 'ASC'}   
    config.create.label = :create_institution_label
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name'
end 
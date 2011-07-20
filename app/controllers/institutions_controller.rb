class InstitutionsController < ApplicationController
  active_scaffold :institution do |config|    
    config.list.sorting = {:name => 'ASC'}   
    config.create.label = :create_institution_label
  end
end 
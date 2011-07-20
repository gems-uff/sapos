class InstitutionsController < ApplicationController
  active_scaffold :institution do |config|    
    config.list.sorting = {:name => 'ASC'}    
  end
end 
class SponsorsController < ApplicationController
  active_scaffold :sponsor do |config|    
    config.list.sorting = {:name => 'ASC'}    
  end
end 
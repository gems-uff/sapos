class SponsorsController < ApplicationController
  active_scaffold :sponsor do |config|    
    config.list.sorting = {:name => 'ASC'}   
    config.create.label = :create_sponsor_label
  end
end 
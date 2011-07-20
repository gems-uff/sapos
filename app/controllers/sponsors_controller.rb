class SponsorsController < ApplicationController
  active_scaffold :sponsor do |config|    
    config.list.label = "Agências de Fomento"
    #config.columns = [:name]
    config.list.sorting = {:name => 'ASC'}
    config.columns[:name].label = "Nome"    
  end
end 
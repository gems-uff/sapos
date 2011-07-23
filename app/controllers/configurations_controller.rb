class ConfigurationsController < ApplicationController  
  def index
    render :text => 'Selecione um item no menu', :layout => true
  end
end 
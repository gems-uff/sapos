class ApplicationController < ActionController::Base
  protect_from_forgery
  ActiveScaffold.set_defaults do |config| 
    config.ignore_columns.add [:created_at, :updated_at, :lock_version]
    config.create.link.label = :create_link
    config.delete.link.label = :delete_link
    config.show.link.label = :show_link
    config.update.link.label = :update_link
    config.search.link.label = :search_link    
    config.delete.link.confirm = :delete_message       
    #Faz com que a busca seja enviada ao servidor enquanto o usuário digita
    config.search.live = true              
    #config.search.link.cancel = false     
  end
end

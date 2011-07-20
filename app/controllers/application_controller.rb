class ApplicationController < ActionController::Base
  protect_from_forgery
  ActiveScaffold.set_defaults do |config| 
    config.ignore_columns.add [:created_at, :updated_at, :lock_version]
    config.create.link.label = "Adicionar"
    config.delete.link.label = "Excluir"    
    config.show.link.label = "Visualizar"
    config.update.link.label = "Editar"
    config.search.link.label = "Pesquisar"    
  end
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class VersionsController < ApplicationController
  authorize_resource

  active_scaffold :version do |config|
    config.columns = [:item_type, :item_id, :event, :whodunnit]
    config.columns[:item_type].label = 'Modelo modificado'
    config.columns[:item_id].label = 'ID do objeto'
    config.columns[:whodunnit].label = 'ID do usuario'

    config.actions.exclude :create, :delete, :update
  end
  record_select :per_page => 10, :search_on => [:item_id]

end

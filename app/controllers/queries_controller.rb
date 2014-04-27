# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class QueriesController < ApplicationController
  authorize_resource

  active_scaffold :query do |config|

    config.update.columns = [:name, :description, :sql]
    config.columns[:description].form_ui = :textarea
    config.columns[:description].options = { :cols => 124, :rows => 3}
    # config.create.columns = form_columns
    # config.show.columns = form_columns + [:next_execution]
    # config.list.columns = [:title, :frequency, :notification_offset, :query_offset, :next_execution]

  end


end

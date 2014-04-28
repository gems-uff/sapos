# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class QueriesController < ApplicationController
  authorize_resource

  active_scaffold :query do |config|

    config.action_links.add 'simulate',
      :label => "<i title='#{I18n.t('active_scaffold.notification.simulate')}' class='fa fa-table'></i>".html_safe,
      :page => true,
      :inline => true,
      :position => :after,
      :type => :member

    config.update.columns = [:name, :description, :params, :sql]
    config.columns[:description].form_ui = :textarea
    config.columns[:description].options = {:cols => 124, :rows => 3}
    config.columns[:params].allow_add_existing = false
    config.columns[:params].clear_link
    # config.create.columns = form_columns
    # config.show.columns = form_columns + [:next_execution]
    # config.list.columns = [:title, :frequency, :notification_offset, :query_offset, :next_execution]

  end


  def simulate
    @query = Query.find(params[:id])
    @messages = @query.execute()
    render :action => 'simulate'
  end

end

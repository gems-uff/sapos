class EmailTemplatesController < ApplicationController
  authorize_resource

  helper :notifications

  active_scaffold :"email_template" do |config|
    config.list.sorting = {:name => 'ASC'}

    columns = [:name, :to, :subject, :body]
    config.create.columns = columns
    config.update.columns = columns
    config.list.columns = columns

    config.actions.exclude :deleted_records    
  end


end

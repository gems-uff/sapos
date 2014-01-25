class NotificationsController < ApplicationController
  authorize_resource

  active_scaffold :"notification" do |config|
  	form_columns = [:title, :frequency, :notification_offset, :query_offset, :sql_query, :to_template, :subject_template, :body_template]
    config.update.columns = form_columns
    config.create.columns = form_columns
    config.show.columns = form_columns + [:last_execution]
    
    config.list.columns = [:title, :frequency, :notification_offset, :query_offset, :last_execution]
    config.create.label = :create_notification_label
  end
end

class NotificationsController < ApplicationController
  authorize_resource

  active_scaffold :"notification" do |config|
  	form_columns = [:title, :frequency, :notification_offset, :query_offset, :sql_query, :to_template, :subject_template, :body_template]
    config.update.columns = form_columns
    config.create.columns = form_columns
    config.show.columns = form_columns + [:next_execution]

    config.columns[:frequency].form_ui = :select
    config.columns[:frequency].options = {:options => Notification::FREQUENCIES}
    
    config.list.columns = [:title, :frequency, :notification_offset, :query_offset, :next_execution]
    config.create.label = :create_notification_label
  end
end

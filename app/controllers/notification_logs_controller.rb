class NotificationLogsController < ApplicationController
  authorize_resource

  active_scaffold :"notification_log" do |config|
  	config.columns = [:notification, :to, :subject, :body, :created_at]
  	config.actions.exclude :create, :delete, :update
  end
end

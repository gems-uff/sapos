class NotificationLogsController < ApplicationController
  authorize_resource

  active_scaffold :"notification_log" do |config|
  	config.columns = [:notification, :to, :subject, :body, :created_at]
  	config.actions.exclude :create, :delete, :update

  	config.list.sorting = {:created_at => 'DESC'}
  end
end

class NotificationLogsController < ApplicationController
  authorize_resource

  active_scaffold :"notification_log" do |config|
  	config.actions.exclude :create, :delete, :update
  end
end

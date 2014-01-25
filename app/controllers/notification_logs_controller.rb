class NotificationLogsController < ApplicationController
  authorize_resource
  
  active_scaffold :"notification_log" do |config|
  end
end

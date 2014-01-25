class NotificationsController < ApplicationController
  authorize_resource
  
  active_scaffold :"notification" do |conf|
  end
end

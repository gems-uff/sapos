class NotificationLog < ActiveRecord::Base
  attr_accessible :body, :notification_id, :subject, :to

  belongs_to :notification
end

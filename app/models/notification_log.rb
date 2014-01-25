class NotificationLog < ActiveRecord::Base
  attr_accessible :to, :body, :subject

  belongs_to :notification
end

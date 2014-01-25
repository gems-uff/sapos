class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :notification_offset, :query_offset, :sql_query, :subject_template, :to_template

  has_many :notification_logs
end

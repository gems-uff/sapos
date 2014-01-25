class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :last_execution, :notification_offset, :query_offset, :sql_query, :subject_template, :to_template

  has_many :notification_logs

  has_paper_trail
end

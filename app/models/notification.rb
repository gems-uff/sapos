class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :last_execution, :notification_offset, :query_offset, :sql_query, :subject_template, :title, :to_template

  has_many :notification_logs

  has_paper_trail

  FREQUENCIES = [I18n.translate("activerecord.attributes.notification.frequencies.annual"), I18n.translate("activerecord.attributes.notification.frequencies.semiannual"), I18n.translate("activerecord.attributes.notification.frequencies.monthly"), I18n.translate("activerecord.attributes.notification.frequencies.weekly"), I18n.translate("activerecord.attributes.notification.frequencies.daily")]
    

  validates :body_template, :presence => true
  validates :frequency, :presence => true, :inclusion => {:in => FREQUENCIES}
  validates :notification_offset, :presence => true
  validates :query_offset, :presence => true
  validates :sql_query, :presence => true
  validates :subject_template, :presence => true
  validates :to_template, :presence => true
end

class NotificationsController < ApplicationController
  authorize_resource

  active_scaffold :"notification" do |config|
  	form_columns = [:title, :frequency, :notification_offset, :query_offset, :sql_query, :to_template, :subject_template, :body_template]
    config.update.columns = form_columns
    config.create.columns = form_columns
    config.show.columns = form_columns + [:last_execution]

    frequency_options = [I18n.translate("activerecord.attributes.notification.frequencies.annual"), I18n.translate("activerecord.attributes.notification.frequencies.semiannual"), I18n.translate("activerecord.attributes.notification.frequencies.monthly"), I18n.translate("activerecord.attributes.notification.frequencies.weekly"), I18n.translate("activerecord.attributes.notification.frequencies.daily")]
    config.columns[:frequency].form_ui = :select
    config.columns[:frequency].options = {:options => frequency_options}
    
    config.list.columns = [:title, :frequency, :notification_offset, :query_offset, :last_execution]
    config.create.label = :create_notification_label
  end
end

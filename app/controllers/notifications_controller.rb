class NotificationsController < ApplicationController
  authorize_resource

  active_scaffold :"notification" do |config|
  	
    config.action_links.add 'execute_now', 
      :label => "<i title='#{I18n.t('active_scaffold.notification.execute_now')}' class='fa fa-mail-forward'></i>".html_safe,
      :page => true, 
      :type => :member

    config.action_links.add 'simulate', 
      :label => "<i title='#{I18n.t('active_scaffold.notification.simulate')}' class='fa fa-table'></i>".html_safe,
      :page => true, 
      :inline => true,
      :type => :member


    config.columns[:frequency].form_ui = :select
    config.columns[:frequency].options = {:options => Notification::FREQUENCIES}
    config.columns[:frequency].description = I18n.t('active_scaffold.notification.frequency_description')
    config.columns[:individual].description = I18n.t('active_scaffold.notification.individual_description')

    form_columns = [:title, :frequency, :notification_offset, :query_offset, :sql_query, :individual, :to_template, :subject_template, :body_template]
    config.update.columns = form_columns
    config.create.columns = form_columns
    config.show.columns = form_columns + [:next_execution]
    config.list.columns = [:title, :frequency, :notification_offset, :query_offset, :next_execution]
    
    config.create.label = :create_notification_label
  end

  def after_update_save(record)
    record.update_next_execution!
  end

  def execute_now
    notification = Notification.find(params[:id])
    Notifier.instance.send_emails notification.execute
    redirect_to Notification
  end

  def simulate
    @notification = Notification.find(params[:id])
    @query_date = @notification.query_date 
    @messages = @notification.execute(:skip_update => true)
    render :action => 'simulate'
  end
end

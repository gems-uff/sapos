class NotificationsController < ApplicationController
  authorize_resource

  active_scaffold :"notification" do |config|
  	

    config.action_links.add 'set_query_date', 
      :label => "<i title='#{I18n.t('active_scaffold.notification.set_query_date')}' class='fa fa-clock-o'></i>".html_safe,
      :page => true, 
      :inline => true,
      :position => :after,
      :type => :member

    config.action_links.add 'execute_now', 
      :label => "<i title='#{I18n.t('active_scaffold.notification.execute_now')}' class='fa fa-mail-forward'></i>".html_safe,
      :page => true, 
      :type => :member

    config.action_links.add 'simulate', 
      :label => "<i title='#{I18n.t('active_scaffold.notification.simulate')}' class='fa fa-table'></i>".html_safe,
      :page => true, 
      :inline => true,
      :position => :after,
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
    query_date = Date.strptime(params[:query_date], "%d-%m-%Y") unless params[:query_date].nil?
    notification = Notification.find(params[:id])
    query_date ||= @notification.query_date.to_date
    Notifier.instance.send_emails(notification.execute(:query_date => query_date.to_time))
    redirect_to Notification
  end

  def simulate
    @query_date = Date.strptime(params[:query_date], "%d-%m-%Y") unless params[:query_date].nil? 
    @notification = Notification.find(params[:id])
    @query_date ||= @notification.query_date.to_date
    @messages = @notification.execute(:skip_update => true, :query_date => @query_date.to_time)
    render :action => 'simulate'
  end

  def set_query_date
    @query_date = Date.strptime(params[:query_date], "%d-%m-%Y") unless params[:query_date].nil?
    @notification = Notification.find(params[:id])
    @query_date ||= @notification.query_date.to_date
    render :action => 'set_query_date'
  end
end

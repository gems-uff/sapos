class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :last_execution, :notification_offset, :query_offset, :sql_query, :subject_template, :title, :to_template

  has_many :notification_logs

  has_paper_trail

  FREQUENCIES = [
    I18n.translate("activerecord.attributes.notification.frequencies.annual"), 
    I18n.translate("activerecord.attributes.notification.frequencies.semiannual"),
    I18n.translate("activerecord.attributes.notification.frequencies.monthly"), 
    I18n.translate("activerecord.attributes.notification.frequencies.weekly"), 
    I18n.translate("activerecord.attributes.notification.frequencies.daily")
  ]
    

  validates :body_template, :presence => true
  validates :frequency, :presence => true, :inclusion => {:in => FREQUENCIES}
  validates :notification_offset, :presence => true
  validates :query_offset, :presence => true
  validates :sql_query, :presence => true
  validates :subject_template, :presence => true
  validates :to_template, :presence => true


  def calculate_next_notification_date(options={})
    time = options[:time]
    time ||= Time.now
    if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
      first_semester = Time.parse("03/01")
      second_semester = Time.parse("08/01")
      dates = [second_semester - 1.year, first_semester, second_semester, first_semester + 1.year]
    else
      dates = [Time.parse("01/01") - 1.year,             Time.parse("01/01"),             Time.parse("01/01") + 1.year]             if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.annual")
      dates = [time.beginning_of_month - 1.month,        time.beginning_of_month,         time.beginning_of_month + 1.month]        if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.monthly")
      dates = [time.beginning_of_week(:monday) - 1.week, time.beginning_of_week(:monday), time.beginning_of_week(:monday) + 1.week] if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.weekly")
      dates = [time.midnight - 1.day,                    time.midnight,                   time.midnight + 1.day]                    if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.daily")    
    end

    #if self.next_execution.nil?
    #  date = dates[0] 
    #else
    date = dates.find { |date| (date + self.notification_offset.days) > time }
    #end
    date + self.notification_offset.days
  end

  def should_send?
    return true if self.last_execution.nil?
    notification_date = self.notification_date
    (self.last_execution <= notification_date) and (Time.now >= notification_date)
  end

end

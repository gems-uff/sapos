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


  def frequency_date
    if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
      first_semester = Time.parse("03/01")
      second_semester = Time.parse("08/01")
      dates = [second_semester - 1.year, first_semester, second_semester, first_semester + 1.year]
      if self.last_execution.nil?
        date = dates[0] 
      else
        date = dates.find { |date| (date + self.notification_offset) >= self.last_execution }
      end
    else
      date = Time.parse("01/01") if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.annual")
      date = Time.now.beginning_of_month if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.monthly")
      date = Time.now.beginning_of_week(:monday) if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.weekly")
      date = Time.now.midnight if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.daily")    
    end
    date
  end

  def notification_date
    self.frequency_date + self.notification_offset
  end

  def query_date
    self.frequency_date + self.query_offset
  end

  def should_execute?
    return true if self.last_execution.nil?
    notification_date = self.notification_date
    (self.last_execution <= notification_date) and (Time.now >= notification_date)
  end
 
end

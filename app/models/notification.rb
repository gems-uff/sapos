class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :next_execution, :notification_offset, :query_offset, :sql_query, :subject_template, :title, :to_template

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

  validate :execution

  after_create :update_next_execution!
  after_initialize :init

  def init
    self.query_offset ||= 0
    self.notification_offset ||= 0
  end

  def calculate_next_notification_date(options={})
    time = options[:time]
    time ||= Time.now
    if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
      first_semester = Time.parse("03/01")
      second_semester = Time.parse("08/01")
      dates = [second_semester - 1.year, first_semester, second_semester, first_semester + 1.year]
    else
      dates = (-2..2).map { |n| Time.parse("01/01") + n.year } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.annual")
      dates = (-2..2).map { |n| time.beginning_of_month + n.month } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.monthly")
      dates = (-2..2).map { |n| time.beginning_of_week(:monday) + n.week } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.weekly")
      dates = (-2..2).map { |n| time.midnight + n.day } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.daily")    
    end

    dates.find { |date| (date + self.notification_offset.days) > time } + self.notification_offset.days
  end

  def update_next_execution!
    self.next_execution = self.calculate_next_notification_date
    self.save!
  end

  def query_date
    next_date = self.next_execution
    next_date = calculate_next_notification_date if next_date.nil?
    next_date + (self.query_offset - self.notification_offset).days
  end

  def execute(options={})
    notifications = []
    
    #Create connection to the Database
    db_connection = ActiveRecord::Base.connection
    
    #Generate query using the parameters specified by the notification
    params = {
      #Temos que definir todos os possíveis parametros que as buscas podem querer usar
      :query_date => db_connection.quote(self.query_date)
    }
    query = (self.sql_query % params).gsub("\r\n", " ")

    #Query the Database
    query_result = db_connection.select_all(query)

    #Build the notifications with the results from the query
    query_result.each do |raw_result|
      result = {}
      raw_result.each do |key , value|
        result[key.to_sym] = value
      end

      notifications << {
        :to => self.to_template % result,
        :subject => self.subject_template % result,
        :body => self.body_template % result
      }
    end
    self.update_next_execution! unless options[:skip_update]
    notifications
  end

  def execution
    begin

      self.execute(:skip_update => true)
    rescue => e
      errors.add(:base, e.to_s)
      
    end
  end

end

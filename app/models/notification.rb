# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :next_execution, :notification_offset, :query_offset, :sql_query, :subject_template, :title, :to_template, :individual

  has_many :notification_logs
  belongs_to :query, :inverse_of => :notifications

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

  before_save do
    if self.query.changed?
      self.query.save
    end
  end

  def to_label
    self.title || I18n.t('activerecord.attributes.notification.no_name')
  end

  def sql_query
    self.query.try(:sql) || ''
  end

  def sql_query=(val)
    self.query.sql= val
  end

  def init
    self.query_offset ||= "0"
    self.notification_offset ||= "0"
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

    dates.find { |date| (date + StringTimeDelta::parse(self.notification_offset)) > time } + StringTimeDelta::parse(self.notification_offset)
  end

  def update_next_execution!
    self.next_execution = self.calculate_next_notification_date
    self.save!
  end

  def query_date
    next_date = self.next_execution
    next_date = calculate_next_notification_date if next_date.nil?
    next_date + StringTimeDelta::parse(self.query_offset) - StringTimeDelta::parse(self.notification_offset)
  end

  def execute(options={})
    notifications = []
    qdate = options[:query_date]
    qdate ||= self.query_date

    #Create connection to the Database
    db_connection = ActiveRecord::Base.connection

    this_semester = YearSemester.on_date qdate
    last_semester = this_semester - 1
    #Generate query using the parameters specified by the notification
    params = {
        #Temos que definir todos os possíveis parametros que as buscas podem querer usar
        :query_date => db_connection.quote(qdate),
        :this_semester_year => this_semester.year,
        :this_semester_number => this_semester.semester,
        :last_semester_year => last_semester.year,
        :last_semester_number => last_semester.semester,

    }

    result = self.query.execute(:override_params => params)

    #Build the notifications with the results from the query
    if self.individual
      result[:rows].each do |raw_result|
        bindings = {}.merge(params)
        bindings.merge!(Hash[result[:columns].zip(raw_result)])

        formatter = ERBFormatter.new(bindings)
        notifications << {
            :notification_id => self.id,
            :to => formatter.format(self.to_template),
            :subject => formatter.format(self.subject_template),
            :body => formatter.format(self.body_template)
        }
      end
    else
      unless result[:rows].empty?
        bindings = {:rows => result[:rows], :columns => result[:columns]}.merge(params)
        formatter = ERBFormatter.new(bindings)
        notifications << {
            :notification_id => self.id,
            :to => formatter.format(self.to_template),
            :subject => formatter.format(self.subject_template),
            :body => formatter.format(self.body_template)
        }
      end
    end
    self.update_next_execution! unless options[:skip_update]
    notifications
  end

  def execution
    begin
      self.execute(:skip_update => true)
    rescue => e
      splitted = e.to_s.split(' -:- ')
      if splitted.size > 1
        field = splitted[0].to_sym
        message = splitted[1..-1].join(' -:- ')
        errors.add(field, ': ' + message)
      else
        errors.add(:base, e.to_s)
      end

    end
  end

end



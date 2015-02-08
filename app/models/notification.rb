# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Notification < ActiveRecord::Base
  attr_accessible :body_template, :frequency, :next_execution, :notification_offset, :query_offset, :sql_query, :subject_template, :title, :to_template, :individual

  has_many :notification_logs
  has_many :notification_params, class_name: 'NotificationParam', dependent: :destroy
  has_many :params, class_name: 'NotificationParam', dependent: :destroy, conditions: {active: true}
  belongs_to :query, :inverse_of => :notifications

  has_paper_trail

  RESERVED_PARAMS = %w{numero_ultimo_semestre ano_ultimo_semestre numero_semestre_atual ano_semestre_atual}

  FREQUENCIES = [
      I18n.translate("activerecord.attributes.notification.frequencies.annual"),
      I18n.translate("activerecord.attributes.notification.frequencies.semiannual"),
      I18n.translate("activerecord.attributes.notification.frequencies.monthly"),
      I18n.translate("activerecord.attributes.notification.frequencies.weekly"),
      I18n.translate("activerecord.attributes.notification.frequencies.daily")
  ]

  validates :body_template, :presence => true, on: :update
  validates :frequency, :presence => true, :inclusion => {:in => FREQUENCIES}, on: :update
  validates :notification_offset, :presence => true, on: :update
  validates :query_offset, :presence => true, on: :update
  validates :subject_template, :presence => true, on: :update
  validates :to_template, :presence => true, on: :update

  validates_format_of :notification_offset, :with => /\A(\-?\d+[yMwdhms]?)+\z/, :message => :offset_invalid_value
  validates_format_of :query_offset, :with => /\A(\-?\d+[yMwdhms]?)+\z/, :message => :offset_invalid_value

  validate do
    execution unless self.new_record?
  end

  after_initialize do
    self.query_offset ||= "0"
    self.notification_offset ||= "0"
    hammer_current_params!
  end

  before_save do
    hammer_current_params! if self.persisted?
    true
  end

  before_create do
    self.frequency = I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
  end
  after_create :update_next_execution!

  def query_params_ids
    (self.query.try(:params) || []).collect &:id
  end

  def build_params_for_creation
    self.query_params_ids.each do |query_param_id|
      self.params.build(:query_param_id => query_param_id, :active => true)
    end
  end

  def hammer_current_params!

    notification_params_ids = (self.notification_params || []).collect &:query_param_id

    new_params = query_params_ids - notification_params_ids

    new_params.each do |query_param_id|
      self.notification_params.create(:query_param_id => query_param_id, :notification_id => self.id, :active => true)
    end

    if self.query_id_changed?
      cached_query_params_ids = self.query_params_ids
      self.notification_params.each do |np|
        np.update_attribute(:active, cached_query_params_ids.include?(np.query_param_id))
      end
    end
  end

  def query_id=(val)
    super
    hammer_current_params!
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

  def calculate_next_notification_date(options={})
    time = options[:time]
    time ||= Time.now
    if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
      first_semester = Time.parse("03/01")
      second_semester = Time.parse("08/01")
      dates = [second_semester - 1.year, first_semester, second_semester, first_semester + 1.year, second_semester + 1.year]
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

  def set_notification_params_values(params)
    params.each do |key, value|
      current_param = self.params.find { |p| p.query_param.name.to_s == key.to_s }
      current_param.value = value if current_param
    end
  end

  def execute(options={})
    notifications = []

    params = prepare_params_and_derivations(options[:override_params] || {})

    set_notification_params_values(params)

    result = self.query.execute(params)

    unless options[:only_validate]
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
    end
    {:notifications => notifications, :query => result[:query]}
  end

  def set_params_for_exhibition(override_params)
    params = self.prepare_params_and_derivations(override_params)
    self.query.map_params(params)
    true
  end

  def prepare_params_and_derivations(override_params)
    override_params[:data_consulta] ||= self.query_date
    qdate = override_params[:data_consulta]
    params = get_query_date_derivations(qdate)
    override_params.merge(params)
  end

  def get_query_date_derivations(qdate)
    if qdate.is_a? String
      return {} if qdate.blank?
      qdate = Date.strptime(qdate, "%Y-%m-%d")
    end
    this_semester = YearSemester.on_date qdate
    last_semester = this_semester - 1
    #Generate query using the parameters specified by the notification
    params = {
        #Temos que definir todos os possíveis parametros que as buscas podem querer usar
        :ano_semestre_atual => this_semester.year,
        :numero_semestre_atual => this_semester.semester,
        :ano_ultimo_semestre => last_semester.year,
        :numero_ultimo_semestre => last_semester.semester,
    }
  end

  def execution
    begin
      self.execute(:skip_update => true, :only_validate => true)
    rescue => e
#///////////////////////////////////////////////////
# A mensagem de erro correta já está sendo exibida
#  O bloco apenas serve para capturar a exceção
#///////////////////////////////////////////////////
#      splitted = e.to_s.split(' -:- ')
#      if splitted.size > 1
#        field = splitted[0].to_sym
#        message = splitted[1..-1].join(' -:- ')
#        errors.add(field, ': ' + message)
#      else
#        errors.add(:base, e.to_s)
#      end
#
      false
    end
  end


  def get_simulation_query_date
    self.params.find { |p| p.name == 'data_consulta' }.simulation_value
  end
end



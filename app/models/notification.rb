# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Notification
class Notification < ApplicationRecord
  has_paper_trail

  belongs_to :query, inverse_of: :notifications, optional: false

  has_many :notification_logs
  has_many :notification_params, class_name: "NotificationParam", dependent: :destroy
  has_many :params, -> { where(active: true) }, class_name: "NotificationParam", dependent: :destroy


  RESERVED_PARAMS = %w{numero_ultimo_semestre ano_ultimo_semestre numero_semestre_atual ano_semestre_atual}

  FREQUENCIES = [
      I18n.translate("activerecord.attributes.notification.frequencies.annual"),
      I18n.translate("activerecord.attributes.notification.frequencies.semiannual"),
      I18n.translate("activerecord.attributes.notification.frequencies.monthly"),
      I18n.translate("activerecord.attributes.notification.frequencies.weekly"),
      I18n.translate("activerecord.attributes.notification.frequencies.daily"),
      I18n.translate("activerecord.attributes.notification.frequencies.manual")
  ]

  validates :query, presence: true, on: :update
  validates :body_template, presence: true, on: :update
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }, on: :update
  validates :notification_offset, presence: true, on: :update
  validates :query_offset, presence: true, on: :update
  validates :subject_template, presence: true, on: :update
  validates :to_template, presence: true, on: :update

  validates_format_of :notification_offset, with: /\A(-?\d+[yMwdhms]?)+\z/, message: :offset_invalid_value
  validates_format_of :query_offset, with: /\A(-?\d+[yMwdhms]?)+\z/, message: :offset_invalid_value

  validate :has_grades_report_pdf_attachment_requirements

  validate :frequency_manual_has_notification_offset_equals_zero

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
    if self.frequency.nil?
      self.frequency = I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
    end
  end
  after_create :update_next_execution!

  def frequency_manual_has_notification_offset_equals_zero
    if (self.notification_offset != "0") && (self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.manual"))
      errors.add(:notification_offset, :manual_frequency_requires_notification_offset_to_be_zero)
    end
  end

  def has_grades_report_pdf_attachment_requirements
    if self.has_grades_report_pdf_attachment
      if ! self.individual
        errors.add(:has_grades_report_pdf_attachment, :individual_required)
      end

      if ! self.query.execute(prepare_params_and_derivations({ data_consulta: Time.zone.now }))[:columns].include?("enrollments_id")
        errors.add(:has_grades_report_pdf_attachment, :query_with_enrollments_id_alias_column_required)
      end
    end
  end

  def query_params_ids
    (self.query.try(:params) || []).collect(&:id)
  end

  def build_params_for_creation
    self.query_params_ids.each do |query_param_id|
      self.params.build(query_param_id: query_param_id, active: true)
    end
  end

  def hammer_current_params!
    notification_params_ids = (self.notification_params || []).collect(&:query_param_id)

    new_params = query_params_ids - notification_params_ids

    new_params.each do |query_param_id|
      self.notification_params.create(query_param_id: query_param_id, notification_id: self.id, active: true)
    end

    if self.will_save_change_to_query_id?
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
    self.title || I18n.t("activerecord.attributes.notification.no_name")
  end

  def sql_query
    self.query.try(:sql) || ""
  end

  def sql_query=(val)
    self.query.sql = val
  end

  def calculate_next_notification_date(options = {})
    time = options[:time]
    time ||= Time.now
    if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.semiannual")
      first_semester = Time.parse("03/01", time)
      second_semester = Time.parse("08/01", time)
      dates = [second_semester - 1.year, first_semester, second_semester, first_semester + 1.year, second_semester + 1.year]
    else
      dates = (-2..2).map { |n| Time.parse("01/01", time) + n.year } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.annual")
      dates = (-2..2).map { |n| time.beginning_of_month + n.month } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.monthly")
      dates = (-2..2).map { |n| time.beginning_of_week(:monday) + n.week } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.weekly")
      dates = (-2..2).map { |n| time.midnight + n.day } if self.frequency == I18n.translate("activerecord.attributes.notification.frequencies.daily")
    end

    dates.find { |date| (date + StringTimeDelta.parse(self.notification_offset)) > time } + StringTimeDelta.parse(self.notification_offset)
  end

  def update_next_execution!
    if self.frequency != I18n.translate("activerecord.attributes.notification.frequencies.manual")
      self.next_execution = self.calculate_next_notification_date
      self.save!
    end
  end

  def query_date
    next_date = self.next_execution
    if self.frequency != I18n.translate("activerecord.attributes.notification.frequencies.manual")
      next_date ||= calculate_next_notification_date
    else
      next_date ||= self.notification_params.find { |p| p.name == "data_consulta" }.try(:value).try(:to_date)
      next_date ||= self.notification_params.find { |p| p.name == "data_consulta" }.try(:query_param).try(:default_value).try(:to_date)
      next_date ||= Date.today
    end
    next_date + StringTimeDelta.parse(self.query_offset) - StringTimeDelta.parse(self.notification_offset)
  end

  def set_notification_params_values(params)
    params.each do |key, value|
      current_param = self.params.find { |p| p.query_param.name.to_s == key.to_s }
      current_param.value = value if current_param
    end
  end

  def execute(options = {})
    notifications = []
    notifications_attachments = {}
    params = prepare_params_and_derivations(options[:override_params] || {})

    set_notification_params_values(params)

    result = self.query.execute(params)

    unless options[:only_validate]
      # Build the notifications with the results from the query
      if self.individual
        result[:rows].each do |raw_result|
          bindings = {}.merge(params)
          bindings.merge!(Hash[result[:columns].zip(raw_result)])

          formatter = ErbFormatter.new(bindings)

          notification = {
              notification_id: self.id,
              to: formatter.format(self.to_template),
              subject: formatter.format(self.subject_template),
              body: formatter.format(self.body_template)
          }

          attachments = {}

          # add grades_report_pdf attachment if required
          if self.has_grades_report_pdf_attachment
            notification[:enrollments_id] = bindings["enrollments_id"]
            attachment_file_name = "#{I18n.t("pdf_content.enrollment.grades_report.title")} -  #{Enrollment.find(bindings["enrollments_id"]).student.name}.pdf"
            attachments[:grades_report_pdf] = { file_name: attachment_file_name }
          end

          notifications << notification
          notifications_attachments[notification] = attachments
        end
      else
        unless result[:rows].empty?
          bindings = { rows: result[:rows], columns: result[:columns] }.merge(params)
          formatter = ErbFormatter.new(bindings)
          notifications << {
              notification_id: self.id,
              to: formatter.format(self.to_template),
              subject: formatter.format(self.subject_template),
              body: formatter.format(self.body_template)
          }
        end
      end
      self.update_next_execution! unless options[:skip_update]
    end
    { notifications: notifications,
      notifications_attachments: notifications_attachments,
      query: result[:query]
    }
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
      qdate = Date.strptime(qdate, "%d/%m/%Y")
    end
    this_semester = YearSemester.on_date qdate
    last_semester = this_semester - 1
    # Generate query using the parameters specified by the notification
    {
      # Temos que definir todos os possíveis parametros que as buscas podem querer usar
      ano_semestre_atual: this_semester.year,
      numero_semestre_atual: this_semester.semester,
      ano_ultimo_semestre: last_semester.year,
      numero_ultimo_semestre: last_semester.semester,
    }
  end

  def execution
    self.execute(skip_update: true, only_validate: true)
  rescue
    # ///////////////////////////////////////////////////
    # A mensagem de erro correta já está sendo exibida
    #  O bloco apenas serve para capturar a exceção
    # ///////////////////////////////////////////////////
    #      splitted = e.to_s.split(" -:- ")
    #      if splitted.size > 1
    #        field = splitted[0].to_sym
    #        message = splitted[1..-1].join(" -:- ")
    #        errors.add(field, ": " + message)
    #      else
    #        errors.add(:base, e.to_s)
    #      end
    #
    false
  end

  def get_simulation_query_date
    self.params.find { |p| p.name == "data_consulta" }.simulation_value
  end
end

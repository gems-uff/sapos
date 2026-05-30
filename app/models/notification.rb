# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Notification
class Notification < ApplicationRecord
  has_paper_trail

  @@disable_erb_validation = false
  LIQUID = record_i18n_attr("template_types.liquid")
  ERB = record_i18n_attr("template_types.erb")

  NOTIFICATION_DROPS = {
    data_consulta: :value,
    ano_semestre_atual: :value,
    numero_semestre_atual: :value,
    ano_ultimo_semestre: :value,
    numero_ultimo_semestre: :value,
  }

  TEMPLATE_TYPES = [LIQUID, ERB]

  DERIVATION_DEFS = {
    "data_consulta" => { name: "data_consulta", value_type: "Date" }
  }
  DERIVED_PARAMS = {
    "numero_ultimo_semestre" => "data_consulta",
    "ano_ultimo_semestre" => "data_consulta",
    "numero_semestre_atual" => "data_consulta",
    "ano_semestre_atual" => "data_consulta",
  }

  ANNUAL = I18n.t("activerecord.attributes.notification.frequencies.annual")
  SEMIANNUAL = I18n.t("activerecord.attributes.notification.frequencies.semiannual")
  MONTHLY = I18n.t("activerecord.attributes.notification.frequencies.monthly")
  WEEKLY = I18n.t("activerecord.attributes.notification.frequencies.weekly")
  DAILY = I18n.t("activerecord.attributes.notification.frequencies.daily")
  MANUAL = I18n.t("activerecord.attributes.notification.frequencies.manual")

  FREQUENCIES = [ANNUAL, SEMIANNUAL, MONTHLY, WEEKLY, DAILY, MANUAL]

  belongs_to :query, inverse_of: :notifications, optional: false

  has_many :notification_logs

  validates :query, presence: true, on: :update
  validates :body_template, presence: true, on: :update
  validates :frequency,
    presence: true,
    inclusion: { in: FREQUENCIES },
    on: :update
  validates :notification_offset, presence: true, on: :update
  validates :query_offset, presence: true, on: :update
  validates :subject_template, presence: true, on: :update
  validates :to_template, presence: true, on: :update

  validates_format_of :notification_offset,
    with: /\A(-?\d+[yMwdhms])*(-?\d*)\z/,
    message: :offset_invalid_value
  validates_format_of :query_offset,
    with: /\A(-?\d+[yMwdhms])*(-?\d*)\z/,
    message: :offset_invalid_value

  validate :has_notification_offset_within_range,
    if: Proc.new { |o| o.errors.empty? }

  validate :has_grades_report_pdf_attachment_requirements

  validate :frequency_manual_has_notification_offset_equals_zero

  validate do
    execution unless self.new_record?
  end

  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }, allow_blank: false
  validate :cannot_create_new_erb_template, if: -> { self.template_type == ERB } 

  after_initialize do
    self.query_offset ||= "0"
    self.notification_offset ||= "0"
  end

  before_create do
    self.frequency = SEMIANNUAL if self.frequency.nil?
  end
  after_create :update_next_execution!

  def frequency_manual_has_notification_offset_equals_zero
    if (self.notification_offset != "0") && (self.frequency == MANUAL)
      errors.add(
        :notification_offset,
        :manual_frequency_requires_notification_offset_to_be_zero
      )
    end
  end

  def has_grades_report_pdf_attachment_requirements
    if self.has_grades_report_pdf_attachment
      if !self.individual
        errors.add(:has_grades_report_pdf_attachment, :individual_required)
      end

      does_not_have_enrollments_id_alias = !self.query.execute(
        prepare_params_and_derivations({ data_consulta: Time.zone.now })
      )[:columns].include?("enrollments_id")
      if does_not_have_enrollments_id_alias
        errors.add(
          :has_grades_report_pdf_attachment,
          :query_with_enrollments_id_alias_column_required
        )
      end
    end
  end

  def has_notification_offset_within_range
    time_delta = StringTimeDelta.parse(self.notification_offset)
    time_delta = -time_delta if time_delta < 0
    errors.add(
      :notification_offset,
      :offset_bigger_than_frequency
    ) if (time_delta >= 365.days && self.frequency == ANNUAL) ||
         (time_delta >= 153.days && self.frequency == SEMIANNUAL) || # 8M - 3M
         (time_delta >= 28.days && self.frequency == MONTHLY) ||
         (time_delta >= 7.days && self.frequency == WEEKLY) ||
         (time_delta >= 1.days && self.frequency == DAILY)
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
    case self.frequency
    when SEMIANNUAL
      first_semester = Time.parse("03/01", time)
      second_semester = Time.parse("08/01", time)
      dates = [
        second_semester - 1.year,
        first_semester, second_semester,
        first_semester + 1.year,
        second_semester + 1.year
      ]
    when ANNUAL
      dates = (-2..2).map { |n| Time.parse("01/01", time) + n.year }
    when MONTHLY
      dates = (-2..2).map { |n| time.beginning_of_month + n.month }
    when WEEKLY
      dates = (-2..2).map { |n| time.beginning_of_week(:monday) + n.week }
    when DAILY
      dates = (-2..2).map { |n| time.midnight + n.day }
    end

    dates.find do |date|
      (date + StringTimeDelta.parse(self.notification_offset)) > time
    end + StringTimeDelta.parse(self.notification_offset)
  end

  def update_next_execution!
    if self.frequency != MANUAL
      self.next_execution = self.calculate_next_notification_date
      self.save!
    end
  end

  def query_date
    next_date = self.next_execution
    if self.frequency != MANUAL
      next_date ||= calculate_next_notification_date
    else
      next_date ||= self.query.params.find { |p| p.name == "data_consulta"}
        .try(:default_value).try(:to_date)
      next_date ||= Date.today
    end
    next_date +
      StringTimeDelta.parse(self.query_offset) -
      StringTimeDelta.parse(self.notification_offset)
  end


  def execute(options = {})
    notifications = []
    notifications_attachments = {}
    params = prepare_params_and_derivations(options[:override_params] || {})

    result = self.query.execute(params)

    unless options[:only_validate]
      # Build the notifications with the results from the query
      if self.individual
        result[:rows].each do |raw_result|
          bindings = {rows: [raw_result], columns: result[:columns]}.merge(params)
          bindings.merge!(Hash[result[:columns].zip(raw_result)])

          formatter = CodeEvaluator.create_formatter(bindings, self.template_type, NOTIFICATION_DROPS)

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

            pdf_title = I18n.t("pdf_content.enrollment.grades_report.title")
            student = Enrollment.find(bindings["enrollments_id"]).student.name
            attachment_file_name = "#{pdf_title} - #{student}.pdf"
            attachments[:grades_report_pdf] = {
              file_name: attachment_file_name
            }
          end

          notifications << notification
          notifications_attachments[notification] = attachments
        end
      else
        unless result[:rows].empty?
          bindings = {
            rows: result[:rows],
            columns: result[:columns]
          }.merge(params)
          formatter = CodeEvaluator.create_formatter(bindings, self.template_type, NOTIFICATION_DROPS)
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
    self.where(active: true).find { |p| p.name == "data_consulta" }.simulation_value
  end

  def self.disable_erb_validation!
    @@disable_erb_validation = true
    yield
    @@disable_erb_validation = false
  end

  private

    def cannot_create_new_erb_template
      return if @@disable_erb_validation
      notification = self.paper_trail.previous_version
      current_to = I18n.transliterate(self.to_template).downcase
      current_subject = I18n.transliterate(self.subject_template).downcase
      current_body = I18n.transliterate(self.body_template).downcase
      while notification.present?
        old_to = I18n.transliterate(notification.to_template).downcase
        old_subject = I18n.transliterate(notification.subject_template).downcase
        old_body = I18n.transliterate(notification.body_template).downcase
        all_same_ERB = (
          current_to == old_to &&
          current_subject == old_subject &&
          current_body == old_body &&
          notification.template_type == ERB
        )
        if all_same_ERB
          return
        end
        notification = notification.paper_trail.previous_version
      end
      errors.add(:body_template, :cannot_create_new_erb_template)
    end
end

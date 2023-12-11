# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledFormField < ActiveRecord::Base
  has_paper_trail

  serialize :list

  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"
  belongs_to :form_field, optional: false,
    class_name: "Admissions::FormField"

  has_many :scholarities, dependent: :delete_all,
    class_name: "Admissions::FilledFormFieldScholarity"

  validates :filled_form, presence: true
  validates :form_field, presence: true

  mount_uploader :file, FormFileUploader

  validate :that_either_value_or_file_is_filled
  validate :that_value_follows_configuration_rules
  validate :size_of_file

  accepts_nested_attributes_for :scholarities, reject_if: :all_blank,
    allow_destroy: true

  after_initialize :set_default_values

  def set_default_values
    return if self.form_field.nil?
    configuration = JSON.parse(self.form_field.configuration || "{}")
    case self.form_field.field_type
    when Admissions::FormField::STRING
      self.value = configuration["default"] if self.value.nil?
    when Admissions::FormField::SELECT
      self.value = configuration["default"] if self.value.nil? &&
        self.form_field.get_values_map("values")[configuration["default"]].present?
    when Admissions::FormField::COLLECTION_CHECKBOX
      self.list = self.form_field.get_values_map("default_values").keys if
        self.list.nil?
    when Admissions::FormField::RADIO
      self.value = configuration["default"] if self.value.nil? &&
        self.form_field.get_values_map("values")[configuration["default"]].present?
    when Admissions::FormField::SINGLE_CHECKBOX
      self.value = configuration["default_check"] ? "1" : "0" if self.value.nil?
    when Admissions::FormField::TEXT, Admissions::FormField::NUMBER, Admissions::FormField::DATE
      self.value = configuration["default"] if self.value.nil?
    end
  end

  def that_either_value_or_file_is_filled
    presence = [self.file.present?, self.value.present?, self.list.present?]
    if presence.count { |x| x } > 1
      add_error(:multiple_filling)
    end
  end

  def that_value_follows_configuration_rules
    return if self.form_field.nil?
    configuration = JSON.parse(self.form_field.configuration || "{}")
    case self.form_field.field_type
    when Admissions::FormField::STRING
      validate_value_required(configuration)
    when Admissions::FormField::SELECT
      validate_value_required(configuration)
    when Admissions::FormField::RADIO
      validate_value_required(configuration)
    when Admissions::FormField::COLLECTION_CHECKBOX
      validate_collection_checkbox(configuration)
    when Admissions::FormField::SINGLE_CHECKBOX
      nil
    when Admissions::FormField::FILE
      validate_file_field(configuration)
    when Admissions::FormField::TEXT
      validate_value_required(configuration)
    when Admissions::FormField::STUDENT_FIELD
      validate_student_field(configuration)
    when Admissions::FormField::CITY
      validate_city_field(configuration)
    when Admissions::FormField::RESIDENCY
      validate_residency_field(configuration)
    when Admissions::FormField::NUMBER
      validate_number_field(configuration)
    when Admissions::FormField::DATE
      validate_date_field(configuration)
    end
  end

  def size_of_file
    return unless self.file.present?
    size = self.file.file.size.to_f
    if size > 15.megabytes.to_f
      add_error(:filesize, count: 15)
      self.file = nil
    end
  end

  def validate_collection_checkbox(configuration)
    if configuration["required"] && self.list.blank?
      add_error(:blank)
    end
    if self.list.present?
      elements = self.list.filter { |x| x.present? }
      mincount = configuration["minselection"].to_i
      if mincount > 0 && elements.length < mincount
        add_error(:minselection, count: mincount)
      end
      maxcount = configuration["maxselection"].to_i
      if maxcount > 0 && elements.length > maxcount
        add_error(:maxselection, count: maxcount)
      end
    end
  end

  def validate_student_field(configuration)
    if configuration["field"] == "photo"
      validate_file_field(configuration, is_photo: true)
    elsif ["special_city", "special_birth_city"].include? configuration["field"]
      validate_city_field(configuration)
    elsif configuration["field"] == "special_address"
      validate_residency_field(configuration)
    else
      validate_value_required(configuration)
    end
    if ["birthdate", "identity_expedition_date"].include? configuration["field"]
      validate_date_field(configuration)
    end
  end

  def validate_city_field(configuration)
    validate_value_required(configuration)
    return if self.value.blank?
    values = self.value.split(" <$> ")
    if configuration["required"] && values[0].blank?
      add_error(:city_blank)
    end
    if configuration["state_required"] && values[1].blank?
      add_error(:state_blank)
    end
    if configuration["country_required"] && values[2].blank?
      add_error(:country_blank)
    end
  end

  def validate_residency_field(configuration)
    validate_value_required(configuration)
    return if self.value.blank?
    values = self.value.split(" <$> ")
    if configuration["required"] && values[0].blank?
      add_error(:street_blank)
    end
    if configuration["number_required"] && values[1].blank?
      add_error(:number_blank)
    end
  end

  def validate_value_required(configuration)
    if configuration["required"] && self.value.blank?
      add_error(:blank)
    end
  end

  def validate_number_field(configuration)
    !!Float(self.value)
  rescue
    add_error(:invalid_number)
  end

  def validate_date_field(configuration)
    return if self.value.blank?
    format_ok = self.value.match(/^\d{1,2}\/\d{1,2}\/\d{2,4}$/)
    parseable = Date.strptime(self.value, "%d/%m/%Y") rescue false
    if !format_ok || !parseable
      add_error(:invalid_date)
    end
  end

  def validate_file_field(configuration, is_photo: false)
    if configuration["required"] && (self.file.blank? || self.file.file.blank?)
      add_error(:blank)
    end
    if configuration["values"] && !(self.file.blank? || self.file.file.blank?)
      values = configuration["values"].dup
      values << ".jpg" if is_photo
      filename = self.file.filename.downcase
      if values.none? { |ext| filename.end_with?(ext.downcase) }
        add_error(:extension, valid: configuration["values"].join(', '))
      end
    end
  end

  def to_label
    return "-" if self.form_field.blank?
    name = self.form_field.name
    return "#{name}: #{self.file}" if self.file.present?
    return "#{name}: #{self.list}" if self.list.present?
    return "#{name}: #{self.value}" if self.value.present?
    "#{name}: -"
  end

  def to_text(blank: "-", field_type: nil, custom: {})
    return blank if self.form_field.blank?
    form_field = self.form_field
    field_type ||= form_field.field_type
    if custom[field_type].present?
      return custom[field_type].call(self, form_field)
    end
    case field_type
    when Admissions::FormField::COLLECTION_CHECKBOX
      default_values = form_field.get_values_map("default_values")
      original_value = form_field.get_values_map("values")
      values_map = original_value.merge(default_values)
      return blank if self.list.blank?
      values = self.list.filter_map { |x| values_map[x] if x.present? }
      values.join(", ")
    when Admissions::FormField::SELECT, Admissions::FormField::RADIO
      return blank if self.value.blank?
      values = form_field.get_values_map("values")
      values[self.value]
    when Admissions::FormField::FILE
      return blank if self.file.blank? || self.file.file.blank?
      self.file.url
    when Admissions::FormField::STUDENT_FIELD
      configuration = JSON.parse(self.form_field.configuration || "{}")
      if ["special_city", "special_birth_city"].include? configuration["field"]
        self.to_text(
          blank: blank, field_type: Admissions::FormField::CITY, custom: custom)
      elsif configuration["field"] == "special_address"
        self.to_text(
          blank: blank, field_type: Admissions::FormField::RESIDENCY, custom: custom)
      elsif configuration["field"] == "special_majors"
        self.to_text(
          blank: blank, field_type: Admissions::FormField::SCHOLARITY, custom: custom)
      elsif configuration["field"] == "photo"
        self.to_text(
          blank: blank, field_type: Admissions::FormField::FILE, custom: custom)
      else
        self.to_text(
          blank: blank, field_type: Admissions::FormField::STRING, custom: custom)
      end
    when Admissions::FormField::CITY
      return blank if self.value.blank?
      values = (self.value || "").split(" <$> ")
      (3 - values.length).times { values << "" }
      values.join(", ")
    when Admissions::FormField::RESIDENCY
      return blank if self.value.blank?
      values = (self.value || "").split(" <$> ")
      values.join(", ")
    when Admissions::FormField::SCHOLARITY
      return blank if self.scholarities.blank?
      values = form_field.get_values_map("values")
      statuses = form_field.get_values_map("statuses")
      self.scholarities.map do |scholarity|
        scholarity.to_label(values: values, statuses: statuses)
      end.join("; ")
    else
      return blank if self.value.blank?
      self.value
    end
  end

  def simple_value
    if self.file.present? && self.file.file.present?
      self.file
    elsif !self.list.nil?
      self.list
    else
      self.value
    end
  end

  def add_error(error, **options)
    attribute = :value
    if self.form_field.field_type == Admissions::FormField::FILE
      attribute = :file
    elsif self.form_field.field_type == Admissions::FormField::COLLECTION_CHECKBOX
      attribute = :list
    end
    if self.class.respond_to?(:i18n_scope)
      i18n_scope = self.class.i18n_scope.to_s
      defaults = self.class.lookup_ancestors.flat_map do |klass|
        [ :"#{i18n_scope}.errors.models.#{klass.model_name.i18n_key}.#{error}" ]
      end
      defaults << :"#{i18n_scope}.errors.messages.#{error}"

      catch(:exception) do
        translation = I18n.translate(defaults.first, **options.merge(default: defaults.drop(1), throw: true))
        return self.errors.add(
          attribute, I18n.t(
            "activerecord.errors.full_messages.format",
            attribute: self.form_field.name,
            message: translation
          )
        ) unless translation.nil?
      end unless options[:message]
    else
      defaults = []
    end
    defaults << :"errors.messages.#{error}"
    key = defaults.shift
    defaults = options.delete(:message) if options[:message]
    options[:default] = defaults
    self.errors.add(attribute, I18n.t(
      "activerecord.errors.full_messages.format",
      attribute: self.form_field.name,
      message: I18n.translate(key, **options)
    ))
  end
end

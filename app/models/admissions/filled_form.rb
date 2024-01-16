# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledForm < ActiveRecord::Base
  has_paper_trail

  attr_accessor :disable_submission

  has_one :admission_application, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionApplication"
  has_one :letter_request, dependent: :restrict_with_exception,
    class_name: "Admissions::LetterRequest"
  has_one :admission_phase_evaluation, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"
  has_one :admission_phase_result, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseResult"
  has_one :admission_ranking_result, dependent: :destroy,
    class_name: "Admissions::AdmissionRankingResult"
  has_many :fields, dependent: :delete_all,
    class_name: "Admissions::FilledFormField"

  belongs_to :form_template, optional: false,
    class_name: "Admissions::FormTemplate"

  accepts_nested_attributes_for :fields, allow_destroy: true

  def to_label
    key = "activerecord.attributes.admissions/filled_form.filled_status"
    key += is_filled ? ".filled" : ".not_filled"
    I18n.t(key, form: self.form_template.to_label)
  end

  def to_fields_hash(result = nil)
    result ||= {}
    self.fields.each do |field|
      result[field.form_field.name] = field
    end
    result
  end

  def prepare_missing_fields
    field_ids = self.form_template.fields.map(&:id)
    filled_field_ids = self.fields.map(&:form_field_id)

    new_filled_fields = field_ids - filled_field_ids
    new_filled_fields.each do |field_id|
      self.fields.new(form_field_id: field_id)
    end
  end

  def sync_fields_before(obj)
    syncs = {}
    self.form_template.fields.where("sync is not null").each do |field|
      syncs[field.id] = obj[Admissions::FormField::SYNCS_MAP[field.sync]]
    end
    self.fields.each do |field|
      if syncs[field.form_field_id].present?
        field.value = syncs[field.form_field_id]
      end
    end
  end

  def sync_fields_after(obj)
    syncs = {}
    self.form_template.fields.where("sync is not null").each do |field|
      syncs[field.id] = Admissions::FormField::SYNCS_MAP[field.sync]
    end
    self.fields.each do |field|
      if syncs[field.form_field_id].present?
        obj[syncs[field.form_field_id]] = field.value
      end
    end
  end

  def consolidate(field_objects: nil, vars: nil)
    # It may raise an exception during the evaluation of consolidations.
    # Please, catch it on caller
    field_objects ||= {}
    vars ||= {}
    fields = {}
    field_objects.each do |name, filled_field|
      fields[name] = filled_field.simple_value
    end
    vars[:fields] = fields

    cfields = self.form_template.fields.order(:order)
    field_ids = cfields.map(&:id)
    filled_field_map = self.fields.index_by(&:form_field_id)
    filled_field_ids = filled_field_map.keys

    old_fields = filled_field_ids - field_ids
    self.fields.where(form_field_id: old_fields).delete_all
    new_filled_fields = field_ids - filled_field_ids
    cfields.each do |form_field|
      if !new_filled_fields.include? form_field.id
        field_objects[form_field.name] = filled_field_map[form_field.id]
        fields[form_field.name] = filled_field_map[form_field.id].simple_value
        next
      end
      configuration = form_field.config_hash
      condition = Admissions::FormCondition.new_from_hash(configuration["condition"])
      skip = !Admissions::FormCondition.check_truth(
        condition, should_raise: Admissions::FormCondition::RAISE_FORM_FIELD
      ) do |name|
        field_objects[name]
      end
      if skip
        value = I18n.t(
          "activerecord.errors.models.admissions/filled_form_field.consolidation.skip"
        )
        field_objects[form_field.name] = self.fields.new(
          form_field_id: form_field.id, value: value
        )
        fields[form_field.name] = value
        next
      end

      case form_field.field_type
      when Admissions::FormField::CODE
        value = CodeEvaluator.evaluate_code(configuration["code"], **vars)
        field_objects[form_field.name] = self.fields.new(
          form_field_id: form_field.id, value: value
        )
        fields[form_field.name] = value
      when Admissions::FormField::EMAIL
        formatter = ErbFormatter.new(vars)
        notification = {
          to: formatter.format(configuration["to"]),
          subject: formatter.format(configuration["subject"]),
          body: formatter.format(configuration["body"])
        }
        Notifier.send_emails(notifications: [notification])
        value = "Para: #{notification[:to]}\nAssunto: #{
          notification[:subject]}\nCorpo:\n#{notification[:body]}"
        field_objects[form_field.name] = self.fields.new(
          form_field_id: form_field.id, value: value
        )
        fields[form_field.name] = value
      end
    end
  end

  def find_cpf_field
    self.fields.includes(:form_field).where(
      form_field: { field_type: Admissions::FormField::STUDENT_FIELD }
    ).each do |filled_field|
      if filled_field.form_field.config_hash["field"] == "cpf"
        return filled_field
      end
    end
    nil
  end
end

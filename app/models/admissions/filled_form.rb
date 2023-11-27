# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledForm < ActiveRecord::Base
  has_paper_trail

  has_one :admission_application, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionApplication"
  has_one :letter_request, dependent: :restrict_with_exception,
    class_name: "Admissions::LetterRequest"
  has_one :admission_phase_evaluation, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"
  has_one :admission_phase_result, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseResult"
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

  def prepare_missing_fields
    field_ids = self.form_template.fields.map(&:id)
    filled_field_ids = self.fields.map(
      &:form_field_id
    )

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
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormTemplate < ActiveRecord::Base
  has_paper_trail

  ADMISSION_FORM = I18n.t(
    "activerecord.attributes.admissions/form_template.template_types.admission_form"
  )
  RECOMMENDATION_LETTER = I18n.t(
    "activerecord.attributes.admissions/form_template.template_types.recommendation_letter"
  )

  TEMPLATE_TYPES = [ADMISSION_FORM, RECOMMENDATION_LETTER]

  has_many :fields, dependent: :destroy,
    class_name: "Admissions::FormField"
  has_many :admission_process_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcess",
    foreign_key: :form_template_id
  has_many :admission_process_letters, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcess",
    foreign_key: :letter_template_id

  validates :name, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }

  def initialize_dup(other)
    super
    self.fields = other.fields.map(&:dup)
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormTemplate < ActiveRecord::Base
  has_paper_trail

  ADMISSION_FORM = record_i18n_attr("template_types.admission_form")
  RECOMMENDATION_LETTER = record_i18n_attr("template_types.recommendation_letter")
  CONSOLIDATION_FORM = record_i18n_attr("template_types.consolidation_form")
  RANKING = record_i18n_attr("template_types.ranking")

  TEMPLATE_TYPES = [
    ADMISSION_FORM, RECOMMENDATION_LETTER, CONSOLIDATION_FORM, RANKING
  ]

  scope :consolidation, -> { where(template_type: CONSOLIDATION_FORM) }
  scope :input_form, -> {
    where(template_type: ADMISSION_FORM)
    .or(where(template_type: RECOMMENDATION_LETTER))
  }

  has_many :fields, dependent: :destroy,
    class_name: "Admissions::FormField"
  has_many :admission_process_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcess",
    foreign_key: :form_template_id
  has_many :admission_process_letters, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcess",
    foreign_key: :letter_template_id
  has_many :phase_member_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionPhase",
    foreign_key: :member_form_id
  has_many :phase_shared_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionPhase",
    foreign_key: :shared_form_id
  has_many :phase_consolidation_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionPhase",
    foreign_key: :consolidation_form_id
  has_one :ranking_config, dependent: :destroy,
    class_name: "Admissions::RankingConfig"
  has_many :admission_report_configs, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionReportConfig",
    foreign_key: :form_template_id

  validates :name, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }

  def initialize_dup(other)
    super
    self.fields = other.fields.map(&:dup)
  end
end

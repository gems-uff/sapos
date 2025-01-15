# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionRankingResult < ActiveRecord::Base
  has_paper_trail

  belongs_to :ranking_config, optional: false,
    class_name: "Admissions::RankingConfig"
  belongs_to :admission_application, optional: false,
    class_name: "Admissions::AdmissionApplication"
  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"

  accepts_nested_attributes_for :filled_form, allow_destroy: true

  validates :ranking_config_id, uniqueness: { scope: [:admission_application_id ] }

  after_initialize :initialize_filled_form

  def initialize_filled_form
    return if self.ranking_config.nil?
    self.filled_form ||= Admissions::FilledForm.new(
      is_filled: false,
      form_template: self.ranking_config.form_template
    )
  end

  def to_label
    "#{self.ranking_config.to_label} / #{self.admission_application.to_label}"
  end

  def filled_position
    rconfig = self.ranking_config
    self.filled_form.fields.each do |field|
      return field if field.form_field_id == rconfig.position_field_id
    end
    self.filled_form.fields.build(form_field_id: rconfig.position_field_id)
  end

  def filled_machine
    rconfig = self.ranking_config
    self.filled_form.fields.each do |field|
      return field if field.form_field_id == rconfig.machine_field_id
    end
    self.filled_form.fields.build(form_field_id: rconfig.machine_field_id)
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::LetterRequest < ActiveRecord::Base
  has_paper_trail

  WAITING = record_i18n_attr("statuses.waiting")
  RECEIVED = record_i18n_attr("statuses.received")

  SHADOW_FIELDS = Set[
    "name", "email", "telephone", "status"
  ]
  SHADOW_FIELDS_MAP = SHADOW_FIELDS.index_by do |field|
    record_i18n_attr(field)
  end

  belongs_to :admission_application, optional: false,
    class_name: "Admissions::AdmissionApplication"

  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"

  validates :admission_application, presence: true
  validates :email, presence: true
  validates :name, presence: true

  before_save :set_access_token

  accepts_nested_attributes_for :filled_form, allow_destroy: true

  after_initialize :initialize_filled_form

  def initialize_filled_form
    return if self.admission_application.blank?
    self.filled_form ||= Admissions::FilledForm.new(
      is_filled: false,
      form_template: self.admission_application.admission_process.letter_template
    )
  end

  def status
    return WAITING if self.filled_form.blank? || !self.filled_form.is_filled
    RECEIVED
  end

  def is_filled
    return false if self.filled_form.blank?
    self.filled_form.is_filled
  end

  private
    def generate_access_token
      token = SecureRandom.urlsafe_base64
      while Admissions::LetterRequest.exists?(access_token: token)
        token = SecureRandom.urlsafe_base64
      end
      token
    end

    def set_access_token
      unless self.access_token?
        self.access_token = generate_access_token
      end
    end
end

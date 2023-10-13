# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::LetterRequest < ActiveRecord::Base
  has_paper_trail

  WAITING = I18n.t("activerecord.attributes.admissions/letter_request.statuses.waiting")
  RECEIVED = I18n.t("activerecord.attributes.admissions/letter_request.statuses.received")

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
    self.filled_form ||= Admissions::FilledForm.new(
      is_filled: false,
      form_template: self.admission_application.admission_process.letter_template
    )
  end

  def status
    return WAITING if self.filled_form.blank? || !self.filled_form.is_filled
    RECEIVED
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

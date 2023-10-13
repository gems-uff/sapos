# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplication < ActiveRecord::Base
  has_paper_trail

  belongs_to :admission_process, optional: false,
    class_name: "Admissions::AdmissionProcess"

  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"

  has_many :letter_requests, dependent: :delete_all,
    class_name: "Admissions::LetterRequest"

  accepts_nested_attributes_for :filled_form,
    allow_destroy: true

  accepts_nested_attributes_for :letter_requests, reject_if: :all_blank,
    allow_destroy: true

  validates :name, presence: true
  validates :email, presence: true
  validates_uniqueness_of :email, scope: :admission_process_id, if: ->(apply) {
    apply.admission_process.present? &&
    !apply.admission_process.allow_multiple_applications
  }

  validate :number_of_letters_in_filled_form

  before_save :set_token

  def number_of_letters_in_filled_form
    return if self.filled_form.blank?
    return if self.admission_process.blank?
    return if !self.admission_process.has_letters
    return if !self.filled_form.is_filled

    min_count = self.admission_process.min_letters.to_i
    max_count = self.admission_process.max_letters.to_i
    if self.letter_requests.length < min_count
      self.errors.add(:base, :min_letters, count: min_count)
    end
    if max_count > 0 && self.letter_requests.length > max_count
      self.errors.add(:base, :max_letters, count: max_count)
    end
  end

  def to_label
    "#{self.name} - #{self.token}"
  end

  def requested_letters
    self.letter_requests.count
  end

  def filled_letters
    self.letter_requests
       .includes(:filled_form)
       .where(filled_form: { is_filled: true }).count
  end

  def missing_letters?
    return false if !self.admission_process.has_letters
    filled_letters = self.letter_requests.count do |letter|
      letter.filled_form.is_filled
    end
    filled_letters < self.admission_process.min_letters.to_i
  end

  def prepare_missing_letters
    process = self.admission_process
    if process.has_letters
      min_letters = process.min_letters.to_i
      new_letters = min_letters - self.letter_requests.count
      if new_letters > 0
        new_letters.times do
          self.letter_requests.new
        end
      end
    end
  end

  private
    def generate_token
      18.times.map { "2346789BCDFGHJKMPQRTVWXY".split("").sample }
        .insert(6, "-").insert(13, "-").join("")
    end

    def generate_valid_token
      token = generate_token
      while Admissions::AdmissionApplication.exists?(token: token) ||
          Admissions::AdmissionApplication.where(
            "admission_process_id = ? AND token LIKE ?",
            self.admission_process_id, "#{token[..6]}%"
          ).first.present?
        # Token must be globally unique
        # First 6 digits of token must be unique for process
        token = generate_token
      end
      token
    end

    def set_token
      unless self.token?
        self.token = generate_valid_token
      end
    end
end

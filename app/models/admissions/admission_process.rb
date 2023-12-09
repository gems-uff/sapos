# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcess < ActiveRecord::Base
  has_paper_trail

  has_many :admission_applications, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionApplication"
  has_many :phases, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcessPhase"

  belongs_to :form_template, optional: false,
    class_name: "Admissions::FormTemplate",  foreign_key: "form_template_id"
  belongs_to :letter_template, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "letter_template_id"

  scope :open, -> {
    where("start_date <= :start_date AND end_date >= :end_date", {
      start_date: Date.today, end_date: Date.today
    })
  }

  validates :form_template, presence: true
  validates :min_letters, numericality: { only_integer: true, greater_than: -1 },
    allow_nil: true
  validates :max_letters, numericality: { only_integer: true, greater_than: -1 },
    allow_nil: true
  validates :name, presence: true
  validates :year, presence: true
  validates :semester,
    presence: true,
    inclusion: { in: YearSemester::SEMESTERS }
  validates :start_date, presence: true
  validates :end_date, presence: true

  validate :end_greater_than_start_date
  validate :max_greater_than_min_letters
  validate :simple_url_is_unique_while_open

  def max_edit_date
    return self.end_date if self.edit_date.nil?
    self.edit_date
  end

  def end_greater_than_start_date
    if self.end_date < self.start_date
      self.errors.add(:base, :end_greater_than_start_date)
    end
  end

  def has_letters
    return false if self.min_letters.nil? && self.max_letters.nil?
    return true if self.max_letters.nil?
    self.max_letters.to_i != 0
  end

  def max_greater_than_min_letters
    return if !self.has_letters
    return if self.max_letters.nil?
    minletters = self.min_letters.to_i
    maxletters = self.max_letters.to_i
    if maxletters < minletters
      self.errors.add(:base, :max_greater_than_min_letters)
    end
  end

  def simple_url_is_unique_while_open
    return if self.end_date < Date.today

    if self.simple_url.to_i.to_s == self.simple_url
      self.errors.add(:simple_url, :simple_url_integer)
    end

    Admissions::AdmissionProcess.where(
      "end_date >= ? and simple_url = ?", Date.today, self.simple_url
    ).each do |other|
      next if other == self
      this_date = self.start_date..self.end_date
      other_date = other.start_date..other.end_date
      if this_date.overlaps?(other_date)
        self.errors.add(:simple_url, :simple_url_collides_in_date_range)
        break
      end
    end
  end

  def is_open?
    self.start_date <= Date.today && self.end_date >= Date.today
  end

  def is_open_to_edit?
    self.start_date <= Date.today && self.max_edit_date >= Date.today
  end

  def admission_applications_count
    self.admission_applications
      .includes(:filled_form)
      .where(filled_form: { is_filled: true }).count
  end

  def year_semester
    "#{self.year}.#{self.semester}"
  end

  def title
    "#{self.name} (#{self.year_semester})"
  end

  def simple_id(closed_behavior: :ignore)
    if self.simple_url.present?
      result = self.simple_url
    else
      result = self.id.to_s
    end
    return result if closed_behavior == :ignore
    return "#{result} (#{
      self.is_open? ? record_i18n_attr("is_open?") :
        record_i18n_attr("is_closed?")
    })" if closed_behavior == :show
    if closed_behavior == :optional_show
      if !self.is_open?
        result += " (#{record_i18n_attr("is_closed?")})"
      end
    end
    result
  end

  def current_phase(options = {})
    time = options[:time]
    time ||= Time.now
    result = nil
    self.phases.order(:order).each do |p|
      if p.start_date.present? && p.start_date <= time
        result = p.admission_phase
      end
    end
    result
  end

  def to_label
    "#{self.title}"
  end
end

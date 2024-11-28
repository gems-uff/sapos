# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionProcess < ActiveRecord::Base
  has_paper_trail

  has_many :admission_applications, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionApplication"
  has_many :phases, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcessPhase"
  has_many :rankings, dependent: :destroy,
    class_name: "Admissions::AdmissionProcessRanking"

  belongs_to :form_template, optional: false,
    class_name: "Admissions::FormTemplate",  foreign_key: "form_template_id"
  belongs_to :letter_template, optional: true,
    class_name: "Admissions::FormTemplate", foreign_key: "letter_template_id"
  belongs_to :level, optional: true
  belongs_to :enrollment_status, optional: true

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

  def initialize_dup(other)
    super
    self.phases = other.phases.map(&:dup)
    self.rankings = other.rankings.map(&:dup)
  end

  def max_edit_date
    return self.end_date if self.edit_date.nil?
    self.edit_date
  end

  def end_greater_than_start_date
    return if self.start_date.nil? || self.end_date.nil?
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
    return if self.end_date.nil?
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
    date = options[:date]
    date ||= Date.today
    result = nil
    self.phases.order(:order).each do |p|
      if p.start_date.present? && p.start_date <= date
        result = p.admission_phase
      end
    end
    result
  end

  def to_label
    "#{self.title}"
  end

  def check_partial_consolidation_conditions(phase_id, pendencies_in_current)
    i18n_prefix = "active_scaffold.admissions/admission_process.consolidate_phase"
    admission_process_phase = self.phases.where(
      admission_phase_id: phase_id
    ).first
    return if phase_id.nil? || admission_process_phase.partial_consolidation

    if self.end_date >= Date.today
      return I18n.t("#{i18n_prefix}.open_process_error")
    end

    non_consolidate_first_phase = self.admission_applications
      .where(admission_phase_id: nil)
      .non_consolidated
      .ready_for_consolidation(nil).size
    if non_consolidate_first_phase > 0
      return I18n.t(
        "#{i18n_prefix}.non_consolidated_error",
        count: non_consolidate_first_phase,
        phase_name: "Candidatura"
      )
    end

    self.phases.order(:order).each do |p|
      if p.admission_phase_id == phase_id
        if pendencies_in_current > 0
          return I18n.t(
            "#{i18n_prefix}.pendencies_in_current_error",
            count: pendencies_in_current,
            phase_name: p.admission_phase.name
          )
        end
        return
      end
      non_consolidate_in_phase = self.admission_applications
        .where(admission_phase_id: p.admission_phase_id)
        .non_consolidated
        .size
      if non_consolidate_in_phase > 0
        return I18n.t(
          "#{i18n_prefix}.non_consolidated_error",
          count: non_consolidate_in_phase,
          phase_name: p.admission_phase.name
        )
      end
    end
  end
end

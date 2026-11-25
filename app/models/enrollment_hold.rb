# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a hold of an Enrollment
class EnrollmentHold < ApplicationRecord
  has_paper_trail

  belongs_to :enrollment, optional: false

  validates :enrollment, presence: true
  validates :number_of_semesters,
    numericality: { greater_than_or_equal_to: 1 }, presence: true
  validates :semester, inclusion: [1, 2], presence: true
  validates :year, presence: true

  validate :validate_dates

  validate :verify_class_enrollments

  after_commit :create_phase_completions
  after_commit :invalidate_enrollment_requests, on: [:create, :update]

  def to_label
    "#{date_label} - #{number_label}"
  end

  def date_label
    "#{year}.#{semester}"
  end

  def number_label
    I18n.t(
      "activerecord.attributes.enrollment_hold.number_label",
      count: number_of_semesters
    )
  end

  def validate_dates
    return if enrollment.blank? || year.nil? || semester.nil?
    admission_date = enrollment.admission_date
    if self.start_date < admission_date
      errors.add(:base, :before_admission_date)
    end
    dismissal = enrollment.dismissal
    if dismissal.present? && dismissal.dismissal_reason.thesis_judgement == DismissalReason::APPROVED
      if self.end_date > dismissal.date
        errors.add(:base, :after_dismissal_date)
      end
    end
  end

  def start_date
    ys = YearSemester.new(year: year, semester: semester)
    ys.semester_begin
  end

  def end_date
    ys = YearSemester.new(year: year, semester: semester)
    (ys + (number_of_semesters - 1)).semester_end
  end

  def create_phase_completions
    enrollment.create_phase_completions
  end

  # Invalida os pedidos de todos os semestres que o trancamento cobre, e nao
  # so o do primeiro: hold_in_date e o check_enrollment_hold da linha do
  # pedido valem ate o end_date, e a adicao que ficasse Solicitada num
  # semestre seguinte travaria toda gravacao do formulario daquele pedido.
  def invalidate_enrollment_requests
    first = YearSemester.new(year: year, semester: semester)
    semesters = (0...number_of_semesters).map { |offset| first + offset }
    by_semester = semesters.map do |ys|
      EnrollmentRequest.where(year: ys.year, semester: ys.semester)
    end
    enrollment_requests = EnrollmentRequest.where(enrollment: enrollment)
      .and(by_semester.reduce(:or))
      .includes(:class_enrollment_requests)

    enrollment_requests.each do |enrollment_request|
      enrollment_request.class_enrollment_requests.each do |class_enrollment_request|
        invalidate_request(class_enrollment_request)
      end
    end
  end

  # A remoção efetivada fica Efetivada, como se espera: a inscrição não pode
  # voltar no período trancado (ClassEnrollmentRequest#
  # that_removal_can_be_undone). A linha que não grava por outro motivo --
  # dado legado que a validação recusa -- continua pendente e travando o
  # formulário do pedido; o log do servidor diz qual e por quê.
  def invalidate_request(class_enrollment_request)
    return if class_enrollment_request.status == ClassEnrollmentRequest::INVALID
    removal_effected = class_enrollment_request.remove_effected?
    return if class_enrollment_request.set_status!(ClassEnrollmentRequest::INVALID)
    return if removal_effected

    Rails.logger.warn(
      "EnrollmentHold #{id}: class enrollment request #{class_enrollment_request.id} " \
      "not invalidated: #{class_enrollment_request.errors.full_messages.join("; ")}"
    )
  end

  def verify_class_enrollments
    class_enrollments = ClassEnrollment.where(enrollment: self.enrollment)
    if class_enrollments.any? { |ce|
      !(ce.course_class.end_date < self.start_date || ce.course_class.start_date > self.end_date)
    }
      errors.add(:base, :class_enrollments_exist)
    end
  end

  def active
    today = Date.current
    today > start_date && today < end_date
  end

  def self.currently_active
    all.select(&:active)
  end

  def self.currently_active_ids
    currently_active.map(&:id)
  end

  def self.currently_active_enrollment_ids
    currently_active.map(&:enrollment_id)
  end

  def self.hold_in_date(enrollment, course_start, course_end)
    return false if enrollment.nil?
    course_start = course_start.to_date
    course_end   = course_end.to_date
    enrollment_holds = enrollment.enrollment_holds
    unless enrollment_holds.empty?
      enrollment_holds.each do |hold|
        return true unless course_end < hold.start_date || course_start > hold.end_date
      end
    end
    false
  end
end

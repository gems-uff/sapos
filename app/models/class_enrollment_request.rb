# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a student EnrollmentRequest for a specific CourseClass
class ClassEnrollmentRequest < ApplicationRecord
  has_paper_trail

  attr_accessor :student_saving, :db_status, :db_action
  # Pedido de turma que a página do aluno não desenha e que o servidor devolve
  # ao envio (StudentEnrollmentController#hidden_insertion_class_ids): a
  # gravação do aluno não o revalida nem o grava.
  attr_accessor :out_of_page

  belongs_to :enrollment_request,
    inverse_of: :class_enrollment_requests, optional: false
  belongs_to :course_class, optional: false
  belongs_to :class_enrollment, optional: true

  has_one :enrollment, through: :enrollment_request

  REQUESTED = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.requested"
  )
  VALID = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.valid"
  )
  INVALID = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.invalid"
  )
  EFFECTED = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.effected"
  )
  STATUSES = [INVALID, REQUESTED, VALID, EFFECTED]
  STATUSES_MAP = {
    INVALID => :invalid,
    REQUESTED => :requested,
    VALID => :valid,
    EFFECTED => :effected
  }

  INSERT = I18n.translate(
    "activerecord.attributes.class_enrollment_request.actions.insert"
  )
  REMOVE = I18n.translate(
    "activerecord.attributes.class_enrollment_request.actions.remove"
  )
  ACTIONS = [INSERT, REMOVE]

  validates :enrollment_request, presence: true
  validates :course_class, presence: true
  validates_uniqueness_of :course_class,
    scope: [:enrollment_request_id], if: -> { !student_saving }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :class_enrollment,
    presence: true, if: -> { status == EFFECTED && action == INSERT }

  # The before_validation :create_or_destroy_class_enrollment makes it always valid
  # validates :class_enrollment,
  #   presence: false, if: -> { status == EFFECTED && action == REMOVE }

  validate :that_class_enrollment_matches_course_and_enrollment,
    if: -> { !student_saving && !marked_for_destruction? }
  # A adição negada não ocupa a disciplina: não há conflito a conferir.
  validate :that_course_class_does_not_exist_in_a_class_enrollment,
    if: -> { !marked_for_destruction? && status != INVALID }
  validate :check_enrollment_hold, unless: -> { status == INVALID }
  validate :that_removal_can_be_undone, if: :undoing_effected_removal?

  before_validation :create_or_destroy_class_enrollment, on: %i[create update]
  after_save :destroy_or_create_class_enrollment
  after_save :set_db_status
  after_initialize :set_db_status

  def self.pendency_condition(user = nil)
    user ||= current_user
    return ["0 = -1"] if user.blank?
    return ["0 = -1"] if user.cannot?(:read_pendencies, ClassEnrollmentRequest)

    cer = Arel::Table.new(ClassEnrollmentRequest.table_name, as: "cer")
    check_status = cer.where(
      cer[:status].not_eq(ClassEnrollmentRequest::EFFECTED)
      .and(cer[:status].not_eq(ClassEnrollmentRequest::INVALID))
    )

    [
      ClassEnrollmentRequest.arel_table[:id].in(
        check_status.project(cer[:id])
      ).to_sql
    ]
  end

  def allocations
    return "" unless course_class = self.course_class
    course_class.allocations.collect do |allocation|
      "#{allocation.day} (#{allocation.start_time}-#{allocation.end_time})"
    end.join("; ")
  end

  def professor
    return nil unless course_class = self.course_class
    course_class.professor.to_label if course_class.professor
  end

  def set_status!(new_status)
    changed = new_status != status ||
      (new_status == EFFECTED && action == INSERT && class_enrollment.blank?) ||
      (new_status == EFFECTED && action == REMOVE && class_enrollment.present?)
    self.status = new_status
    changed && save
  end

  def insert_effected?
    self.action == ClassEnrollmentRequest::INSERT &&
    self.status == ClassEnrollmentRequest::EFFECTED
  end

  def insert_not_effected?
    self.action == ClassEnrollmentRequest::INSERT &&
    self.status != ClassEnrollmentRequest::EFFECTED
  end

  def remove_effected?
    self.action == ClassEnrollmentRequest::REMOVE &&
    self.status == ClassEnrollmentRequest::EFFECTED
  end

  def remove_not_effected?
    self.action == ClassEnrollmentRequest::REMOVE &&
    self.status != ClassEnrollmentRequest::EFFECTED
  end

  def check_enrollment_hold
    if self.course_class && EnrollmentHold.hold_in_date(enrollment, self.course_class.start_date, self.course_class.end_date)
      errors.add(:enrollment, :enrollment_is_held)
    end
  end

  protected
    def that_class_enrollment_matches_course_and_enrollment
      ce = self.class_enrollment
      return if ce.blank?
      return if ce.course_class_id == self.course_class_id &&
        ce.enrollment_id == self.enrollment_request.enrollment_id

      errors.add(
        :class_enrollment, :must_represent_the_same_enrollment_and_class
      )
    end

    def that_course_class_does_not_exist_in_a_class_enrollment
      return if action != INSERT
      return if enrollment_request.blank? || course_class.blank?
      enrollment = self.enrollment_request.enrollment
      return if enrollment.blank?

      course = course_class.course
      return if course.course_type.allow_multiple_classes

      conflicts = enrollment.class_enrollments.select do |enrollment_class|
        enrollment_class.course_class.course_id == course.id &&
          enrollment_class != class_enrollment &&
          enrollment_class.situation != ClassEnrollment::DISAPPROVED
      end
      return if conflicts.empty?

      if conflicts.any? { |ce| ce.situation == ClassEnrollment::APPROVED }
        return errors.add(:course_class, :previously_approved)
      end
      blocking = conflicts.filter_map { |ce| conflict_with_registered(ce) }
      return if blocking.empty?

      if blocking.include?(:already_enrolled)
        errors.add(:course_class, :already_enrolled)
      else
        errors.add(:course_class, :remove_first)
      end
    end

    # Troca de turma (#781): a inscrição registrada na disciplina não impede o
    # pedido de outra turma se o mesmo pedido de inscrição traz a remoção dela.
    # Na efetivação a regra volta a ser estrita -- nunca duas inscrições
    # ativas --, a menos que a remoção seja efetivada na mesma gravação (o
    # formulário do pedido de inscrição). Devolve o erro, ou nil se não barra.
    #
    # A remoção se acha pela turma, não pela inscrição: efetivada na mesma
    # gravação, ela apaga a inscrição já na validação e perde o vínculo.
    # Efetivada, ela só libera se a inscrição de fato sumiu: a inscrição pode
    # voltar pela tela de inscrições sem que o status da remoção mude. Quem
    # responde é o banco: a lista de inscrições do aluno, carregada antes, não
    # traz o objeto que a remoção apagou, e sim uma cópia que não sabe disso.
    def conflict_with_registered(enrollment_class)
      removal = enrollment_request.class_enrollment_requests.find do |cer|
        cer != self && cer.action == REMOVE &&
          cer.course_class_id == enrollment_class.course_class_id
      end
      return :already_enrolled if removal.nil? || removal.status == INVALID
      if removal.status == EFFECTED
        return nil unless ClassEnrollment.unscoped.exists?(enrollment_class.id)
        return :already_enrolled
      end
      return nil if status != EFFECTED
      :remove_first
    end

    # Desfazer a remoção efetivada recria a inscrição removida (after_save
    # destroy_or_create_class_enrollment), e a gravação dela, recusada, não
    # chegaria a ninguém: o autosave do belongs_to a descarta. Monta-se aqui a
    # inscrição que seria recriada e recusa-se com o motivo dela -- por
    # exemplo, a adição da troca já efetivada na mesma disciplina.
    def undoing_effected_removal?
      action == REMOVE && status != EFFECTED &&
        status_in_database == EFFECTED && class_enrollment.blank? &&
        !marked_for_destruction?
    end

    def that_removal_can_be_undone
      return if enrollment_request.blank? || course_class.blank?
      restored = ClassEnrollment.new(
        enrollment: enrollment_request.enrollment,
        course_class: course_class,
        situation: ClassEnrollment::REGISTERED
      )
      return if restored.valid?

      restored.errors.full_messages.each { |message| errors.add(:base, message) }
    end

    def create_or_destroy_class_enrollment
      return if status != EFFECTED

      if action == INSERT && class_enrollment.blank?
        self.class_enrollment = ClassEnrollment.new(
          enrollment: enrollment_request.enrollment,
          course_class: course_class,
          situation: ClassEnrollment::REGISTERED
        )
      end
      removing_class_enrollment = (
        action == REMOVE &&
        class_enrollment.present? && class_enrollment.can_destroy?
      )
      if removing_class_enrollment
        class_enrollment.destroy!
      end
    end

    def destroy_or_create_class_enrollment
      return if self.status == EFFECTED

      inserting_removal = (
        action == INSERT &&
        class_enrollment.present? && class_enrollment.can_destroy?
      )
      # Desliga antes de apagar: o after_destroy da inscrição
      # (ClassEnrollment#set_request_status_after_destroy), pensado para a
      # exclusão pela tela de inscrições, marcaria esta linha como Inválida.
      if inserting_removal
        released = class_enrollment
        self.class_enrollment = nil
        update_column(:class_enrollment_id, nil)
        released.destroy
      end
      if action == REMOVE && class_enrollment.blank?
        self.class_enrollment = ClassEnrollment.new(
          enrollment: enrollment_request.enrollment,
          course_class: course_class,
          situation: ClassEnrollment::REGISTERED
        )
        save
      end
    end

    def set_db_status
      self.db_status = status
      self.db_action = action
    end
end

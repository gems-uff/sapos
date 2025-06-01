# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents an User
class User < ApplicationRecord
  has_paper_trail
  attr_accessor :max_role_was

  scope :professors, -> { joins(:roles).where(roles: { id: Role::ROLE_PROFESSOR }) }
  scope :coordination, -> { joins(:roles).where(roles: { id: Role::ROLE_COORDENACAO }) }
  scope :secretary, -> { joins(:roles).where(roles: { id: Role::ROLE_SECRETARIA }) }

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_one :professor
  has_one :student, dependent: :nullify
  has_many :enrollment_request_comments, dependent: :destroy
  has_many :admission_committee_members, dependent: :destroy,
    class_name: "Admissions::AdmissionCommitteeMember"
  has_many :admission_phase_evaluations, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"
  has_many :admission_pendencies, dependent: :destroy,
    class_name: "Admissions::AdmissionPendency"

  devise :invitable,
    :database_authenticatable, :recoverable, :rememberable, :registerable,
    :trackable, :confirmable, :lockable

  before_create :set_default_actual_role

  after_create :skip_confirmation!,
    unless: Proc.new { self.invitation_token.nil? }

  validates :user_roles, presence: false
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validate :roles_valid?
  validate :role_is_professor_if_the_professor_field_is_filled
  validate :role_is_student_if_the_student_field_is_filled
  validate :selected_professor_is_already_linked_to_another_user
  validate :selected_student_is_already_linked_to_another_user

  validates_confirmation_of :password

  before_destroy :validate_destroy

  delegate :can?, :cannot?, to: :ability

  def ability
    @ability ||= Ability.new(self)
  end

  def is_professor?
    roles.any? { |role| role.id == Role::ROLE_PROFESSOR }
  end

  def is_student?
    roles.any? { |role| role.id == Role::ROLE_ALUNO }
  end

  def to_label
    "#{self.name}"
  end

  def roles_valid?
    return if current_user.blank?

    self.roles << Role.find_by(id: Role::ROLE_DESCONHECIDO) if roles.blank?

    unless self.id == current_user.id && current_user.max_role_was == self.max_role_was
      current_user_role_index = Role::ORDER.index(current_user.actual_role)
      if self.max_role_was.present? && current_user_role_index < Role::ORDER.index(self.max_role_was)
        errors.add(:base, :invalid_role_was)
      end
      if current_user_role_index < Role::ORDER.index(self.user_max_role)
        errors.add(:base, :invalid_role)
      end
    end
  end

  # Application need a user to log in
  def validate_destroy
    errors.add(:base, :delete) if User.count == 1
    unless current_user.blank?
      role_index = Role::ORDER.index(current_user.actual_role)
      if role_index < Role::ORDER.index(self.user_max_role)
        errors.add(:base, :invalid_role_full)
      end
      if current_user.id == self.id
        errors.add(:base, :self_delete)
      end
    end
    if errors.present?
      throw(:abort)
    end
  end

  def role_is_professor_if_the_professor_field_is_filled
    if professor && !is_professor?
      errors.add(:professor, :selected_role_was_not_professor)
    end
    if is_professor? && !professor
      errors.add(:base, :role_professor_not_associated)
    end
  end

  def role_is_student_if_the_student_field_is_filled
    if student && !self.is_student?
      errors.add(:student, :selected_role_was_not_student)
    end
    if !student && self.is_student?
      errors.add(:base, :role_student_not_associated)
    end
  end


  def selected_professor_is_already_linked_to_another_user
    return if professor.blank?
    return unless professor.errors.messages[:user].include? I18n.t(
      "activerecord.errors.models.professor.attributes.user.changed_to_different_user"
    )
    errors.add(
      :professor,
      :selected_professor_is_already_linked_to_another_user,
      nome_usuario: User.find(professor.user_id_was).name
    )
  end

  def selected_student_is_already_linked_to_another_user
    return if student.blank?
    return unless student.errors.messages[:user].include? I18n.t(
      "activerecord.errors.models.student.attributes.user.changed_to_different_user"
    )
    errors.add(
      :student,
      :selected_student_is_already_linked_to_another_user,
      nome_usuario: User.find(student.user_id_was).name
    )
  end

  def self.find_for_database_authentication(conditions = {})
    user = self.find_by(email: conditions[:email])
    return user if user.present?

    cpf = nil
    cpf = conditions[:email].gsub(/[.-]/, "") if !conditions[:email].include? "@"
    unless cpf.nil?
      self.joins(:professor).where(
        "REPLACE(REPLACE(professors.cpf, '-', ''), '.', '') = ?", cpf
      ).first ||
      self.joins(:student).where(
        "REPLACE(REPLACE(students.cpf, '-', ''), '.', '') = ?", cpf
      ).first
    end
  end

  def user_max_role
    if self.roles.present?
      max_role = self.roles.max_by { |role| Role::ORDER.index(role.id) }
      max_role.id
    end
  end

  def roles=(value)
    self.max_role_was ||= self.user_max_role
    super
  end

  private
    def set_default_actual_role
      self.actual_role = actual_role.present? ? actual_role : user_max_role
    end

    def store_max_role_was
      self.max_role_was = self.user_max_role
    end
end

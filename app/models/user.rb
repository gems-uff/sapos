# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents an User
class User < ApplicationRecord
  has_paper_trail

  belongs_to :role, optional: false

  has_one :professor
  has_one :student, dependent: :nullify
  has_many :enrollment_request_comments, dependent: :destroy
  has_many :admission_committee_members, dependent: :destroy,
    class_name: "Admissions::AdmissionCommitteeMember"
  has_many :admission_phase_evaluations, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"

  devise :invitable,
    :database_authenticatable, :recoverable, :rememberable, :registerable,
    :trackable, :confirmable, :lockable

  after_create :skip_confirmation!,
    unless: Proc.new { self.invitation_token.nil? }

  validates :role, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validate :role_valid?
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

  def to_label
    "#{self.name}"
  end

  def role_valid?
    return if current_user.blank?
    return if role.blank?

    role_index = Role::ORDER.index(current_user.role.id)
    if role_index < Role::ORDER.index(self.role_id_was)
      errors.add(:role, :invalid_role_was)
    end
    if role_index < Role::ORDER.index(role.id)
      errors.add(:role, :invalid_role)
    end
  end

  # Application need a user to log in
  def validate_destroy
    errors.add(:base, :delete) if User.count == 1
    unless current_user.blank?
      role_index = Role::ORDER.index(current_user.role.id)
      if role_index < Role::ORDER.index(self.role.id)
        errors.add(:base, :invalid_role_full)
      end
      if current_user.id == self.id
        errors.add(:base, :self_delete)
      end
    end
    errors.blank?
  end

  def role_is_professor_if_the_professor_field_is_filled
    if professor && (role.id != Role::ROLE_PROFESSOR)
      errors.add(:professor, :selected_role_was_not_professor)
    end
  end

  def role_is_student_if_the_student_field_is_filled
    if student && (role.id != Role::ROLE_ALUNO)
      errors.add(:student, :selected_role_was_not_student)
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
end

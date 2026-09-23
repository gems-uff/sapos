# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Professor
class Professor < ApplicationRecord
  include ::UserNameSyncConcern

  has_paper_trail

  has_many :advisements, dependent: :restrict_with_exception
  has_many :enrollments, through: :advisements
  has_many :scholarships, dependent: :restrict_with_exception
  has_many :advisement_authorizations, dependent: :restrict_with_exception
  has_many :professor_research_areas, dependent: :destroy
  has_many :research_areas, through: :professor_research_areas
  has_many :professor_research_lines, dependent: :destroy
  has_many :research_lines, through: :professor_research_lines
  has_many :course_classes, dependent: :restrict_with_exception
  has_many :thesis_defense_committee_participations,
    dependent: :restrict_with_exception
  has_many :thesis_defense_committee_enrollments,
    source: :enrollment, through: :thesis_defense_committee_participations
  has_many :affiliations, dependent: :destroy
  has_many :institutions, through: :affiliations
  accepts_nested_attributes_for :affiliations, allow_destroy: false, reject_if: :all_blank

  belongs_to :city, optional: true
  belongs_to :academic_title_country,
    optional: true,
    class_name: "Country",
    foreign_key: "academic_title_country_id"
  belongs_to :academic_title_institution,
    optional: true, class_name: "Institution",
    foreign_key: "academic_title_institution_id"
  belongs_to :academic_title_level,
    optional: true, class_name: "Level",
    foreign_key: "academic_title_level_id"
  belongs_to :user, optional: true

  validates :cpf, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, uniqueness: true, allow_nil: true, allow_blank: true
  validates :enrollment_number, uniqueness: true, allow_blank: true
  validate :changed_to_different_user

  before_destroy :handle_user_role_removal

  ADVISEMENT_POINTS_OF_LEVEL_PATTERN =
    /\Aadvisement_points_of_level(\d+)(_order)?\z/

  def method_missing(name, *args, &block)
    match = ADVISEMENT_POINTS_OF_LEVEL_PATTERN.match(name.to_s)
    return super unless match

    points = advisement_points(match[1])
    match[2] ? points.to_f : points
  end

  def respond_to_missing?(name, include_private = false)
    ADVISEMENT_POINTS_OF_LEVEL_PATTERN.match?(name.to_s) || super
  end

  # It was considered that active advisements were enrollments without dismissals reasons
  def advisement_points(level_id = nil)
    # Pontua quem está credenciado hoje, em qualquer nível: o descredenciado
    # não pontua nem na matrícula em que o coorientador ainda é vigente.
    return "#{0.0}" unless self.accredited?

    enrollments = Enrollment.joins([
      "LEFT OUTER JOIN dismissals ON enrollments.id = dismissals.enrollment_id",
      :advisements
    ]).where(
      "advisements.professor_id = :professor_id AND dismissals.id IS NULL",
      professor_id: self.id
    )

    if level_id != nil
      enrollments = enrollments.where(level_id: level_id.to_i)
    end

    # Conta, para cada matrícula, quantos orientadores têm credenciamento
    # VIGENTE hoje -- não quantos já foram credenciados algum dia. É
    # correlacionada com a matrícula da consulta externa, por isso entra como
    # texto; o to_sql vem de uma relação montada pelo Rails, sem entrada do
    # usuário.
    authorized_advisors = Advisement
      .where("advisements.enrollment_id = enrollments.id")
      .where(professor_id: AdvisementAuthorization.on_date(Date.current).select(:professor_id))
      .select("COUNT(*)")
      .to_sql

    enrollments_with_single_advisor = enrollments.where("1 = (#{authorized_advisors})")
    enrollments_with_multiple_advisors = enrollments.where("1 < (#{authorized_advisors})")

    points = 0.0
    points += (
      CustomVariable.multiple_advisor_points *
        enrollments_with_multiple_advisors.count +
      CustomVariable.single_advisor_points *
        enrollments_with_single_advisor.count
    )
    "#{points.to_f}"
  end

  def advisement_points_order
    advisement_points.to_f
  end

  def advisement_point(enrollment)
    # A mesma regra de advisement_points, para as duas somarem igual:
    # credenciamento vigente em qualquer nível, não no nível da matrícula.
    return 0.0 unless self.accredited?
    return 0.0 if enrollment.advisements.where(professor_id: self.id).empty?
    return 0.0 if enrollment.dismissal
    authorized_advisors = enrollment.advisements
      .where(professor_id: AdvisementAuthorization.on_date(Date.current).select(:professor_id))
      .count
    if authorized_advisors.to_i == 1
      CustomVariable.single_advisor_points
    else
      CustomVariable.multiple_advisor_points
    end
  end

  def to_label
    "#{self.name}"
  end

  # True when the professor holds an accreditation valid on +date+ at any level.
  def accredited?(date = Date.current)
    advisement_authorizations.any? { |auth| auth.active_on?(date) }
  end

  # True when the professor holds an accreditation valid on +date+ for +level+.
  # Iterates the loaded association in memory on purpose, so advisements being
  # validated with not-yet-saved (nested) authorizations are still considered.
  def accredited_on?(level, date = Date.current)
    advisement_authorizations.any? do |auth|
      auth.level == level && auth.active_on?(date)
    end
  end

  def changed_to_different_user
    if (user_id_changed?) && (!user_id.blank?) && (!user_id_was.blank?)
      errors.add(:user, :changed_to_different_user)
    end
  end

  private
    def handle_user_role_removal
      return unless user.present?

      professor_role = Role.find_by(id: Role::ROLE_PROFESSOR)
      if user.roles.include?(professor_role)
        user.roles.delete(professor_role)

        user.roles << Role.find_by(id: Role::ROLE_DESCONHECIDO) if user.roles.empty?

        if user.actual_role == Role::ROLE_PROFESSOR
          user.actual_role = user.user_max_role || Role::ROLE_DESCONHECIDO
        end

        user.save!
      end
    end
end

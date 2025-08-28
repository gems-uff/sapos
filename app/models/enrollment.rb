# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Student Enrollment of a Level in a ResearchArea with a EnrollmentStatus
class Enrollment < ApplicationRecord
  include ::MonthYearConcern
  attr_readonly :professors
  attribute :new_user_mode, :string, default: "default"

  has_paper_trail

  belongs_to :student, optional: false
  belongs_to :level, optional: false
  belongs_to :enrollment_status, optional: false
  belongs_to :research_area, optional: true

  has_one :dismissal, dependent: :restrict_with_exception
  has_many :advisements, dependent: :destroy
  has_many :professors, through: :advisements
  has_many :scholarship_durations, dependent: :destroy
  has_many :scholarships, through: :scholarship_durations
  has_many :accomplishments, dependent: :destroy
  has_many :phases, through: :accomplishments
  has_many :deferrals, dependent: :destroy
  has_many :enrollment_holds, dependent: :destroy
  has_many :class_enrollments, dependent: :destroy
  has_many :thesis_defense_committee_participations, dependent: :destroy
  has_many :thesis_defense_committee_professors,
    source: :professor,
    through: :thesis_defense_committee_participations
  has_many :phase_completions, dependent: :destroy
  has_many :admission_applications, dependent: :nullify,
    class_name: "Admissions::AdmissionApplication"

  validates :enrollment_number, presence: true, uniqueness: true
  validates :admission_date, presence: true
  validates :level, presence: true
  validates :enrollment_status, presence: true
  validates :student, presence: true
  validates_associated :dismissal
  validate :enrollment_has_main_advisor

  validates_date :thesis_defense_date,
    on_or_after: :admission_date,
    allow_nil: true,
    on_or_after_message: :thesis_defense_date_before_admission_date

  validate :verify_research_area_with_advisors

  after_save :create_phase_completions
  after_create :create_user!

  month_year_date :admission_date


  def to_label
    return enrollment_number if student.nil?
    "#{enrollment_number} - #{student.name}"
  end

  def available_semesters
    self.class_enrollments.joins(course_class: :course)
      .group("course_classes.year", "course_classes.semester")
      .order("course_classes.year", "course_classes.semester")
      .select(["course_classes.year", "course_classes.semester"])
      .collect { |y| [y.year, y.semester] }
  end

  def gpr_by_semester(year, semester)
    result = self.class_enrollments
      .joins(course_class: { course: :course_type })
      .where(
        "course_classes.year" => year,
        "course_classes.semester" => semester,
        "course_types.has_score" => true)
      .where(
        ClassEnrollment.arel_table[:situation]
        .not_eq(ClassEnrollment::REGISTERED)
      )
      .where(class_enrollments: { grade_not_count_in_gpr: [0, nil] })
      .select("sum(credits*grade) as grade, sum(credits) as credits")
    return if result[0]["credits"].blank?

    result[0]["grade"].to_f / result[0]["credits"].to_f
  end

  def total_gpr
    result = self.class_enrollments
      .joins(course_class: { course: :course_type })
      .where("course_types.has_score" => true)
      .where(
        ClassEnrollment.arel_table[:situation]
        .not_eq(ClassEnrollment::REGISTERED)
      )
      .where(class_enrollments: { grade_not_count_in_gpr: [0, nil] })
      .select("sum(credits*grade) as grade, sum(credits) as credits")
    return if result[0]["credits"].blank?

    result[0]["grade"].to_f / result[0]["credits"].to_f
  end

  def self.with_delayed_phases_on(date, phases)
    date = Date.today if date.nil?
    phases = Phase.all if phases.nil?
    phases_ids = phases.map(&:id)

    Enrollment.joins(phase_completions: :phase).includes(:dismissal)
      .where("phases.active" => true)
      .where(phase_completions: {
        completion_date: nil,
        phase_id: phases_ids
      })
      .where(PhaseCompletion.arel_table[:due_date].lt(date))
      .where(
        Dismissal.arel_table[:date].gt(date)
        .or(Dismissal.arel_table[:enrollment_id].eq(nil))
      ).references(:dismissals).map(&:id).uniq
  end

  def delayed_phases(options = {})
    date ||= options[:date]
    date ||= Date.today
    self.phase_completions.joins(:phase)
      .where("phases.active" => true)
      .where(PhaseCompletion.arel_table[:due_date].lt(date))
      .where(completion_date: nil).collect { |pc| pc.phase }
  end

  def phase_completions_show
    phase_completions
  end

  def self.with_all_phases_accomplished_on(date)
    enrollments = Enrollment.all
    enrollments_with_all_phases_accomplished = []
    enrollments.each do |enrollment|
      accomplished_phases = Accomplishment.where(
        "
          enrollment_id = :enrollment_id
          and DATE(conclusion_date) <= DATE(:conclusion_date)
        ",
        enrollment_id: enrollment.id,
        conclusion_date: date
      ).map { |ac| ac.phase }
      phases_duration = PhaseDuration.where(
        "level_id = :level_id",
        level_id: enrollment.level_id
      )
      phases_duration = phases_duration.where(
        "phase_id not in (:accomplished_phases)",
        accomplished_phases: accomplished_phases
      ) if accomplished_phases.present?
      next if phases_duration.present?

      enrollments_with_all_phases_accomplished << enrollment.id
    end
    enrollments_with_all_phases_accomplished
  end

  def enrollment_has_main_advisor
    unless advisements.blank?
      main_advisors = 0
      advisements.each do |a|
        main_advisors += 1 if a.main_advisor
      end
      errors.add(:base, :main_advisor_required) if main_advisors == 0
      errors.add(:base, :main_advisor_uniqueness) if main_advisors > 1
    end
  end

  def verify_research_area_with_advisors
    return if advisements.blank?
    return if research_area.blank?

    research_areas = []
    advisements.each do |advisement|
      next if advisement.professor.research_areas.blank?
      research_areas += advisement.professor.research_areas
    end

    return if research_areas.include? research_area
    errors.add(:research_area, :research_area_different_from_professors)
  end

  def create_phase_completions
    PhaseCompletion.where(enrollment_id: id).destroy_all

    PhaseDuration.where(level_id: level_id).each do |phase_duration|
      PhaseCompletion.new(
        enrollment: self,
        phase: phase_duration.phase
      ).save
    end
  end

  def has_active_scholarship_now?
    scholarship_durations.each do |scholarship_duration|
      return true if scholarship_duration.active?
    end
    false
  end

  def should_have_user?
    return false unless self.student.can_have_new_user?
    return false unless self.enrollment_status.user
    return true if new_user_mode == "default" && self.dismissal.nil?
    return true if new_user_mode == "dismissed" && ! self.dismissal.nil?
    return true if new_user_mode == "all"
    false
  end

  def create_user!
    return false unless self.should_have_user?
    begin
      student = self.student
      role = Role.find_by(id: Role::ROLE_ALUNO)
      user = User.invite!({
        email: student.first_email,
        name: student.name,
        roles: [role],
      }, current_user) do |invitable|
        invitable.skip_confirmation!
      end
      student.user = user
      student.save
    rescue StandardError
      eusers = User.where({ email: self.student.first_email })
      eusers.destroy_all
      return false
    end
    true
  end

  def completed_or_active_phase_completions
    phase_completions.joins(:phase)
      .where.not(completion_date: nil)
      .or(phase_completions.joins(:phase)
      .where("phases.active" => true))
  end
end

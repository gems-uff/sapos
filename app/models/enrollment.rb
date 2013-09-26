# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Enrollment < ActiveRecord::Base
  attr_accessible :enrollment_number
  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
  has_one :dismissal, :dependent => :destroy
  has_many :advisements, :dependent => :destroy
  has_many :professors, :through => :advisements
  has_many :scholarship_durations, :dependent => :destroy
  has_many :scholarships, :through => :scholarship_durations
  has_many :accomplishments, :dependent => :destroy
  has_many :phases, :through => :accomplishments
  has_many :deferrals, :dependent => :destroy
  has_many :class_enrollments, :dependent => :destroy

  validates :enrollment_number, :presence => true, :uniqueness => true
  validates :level, :presence => true
  validates :enrollment_status, :presence => true
  validates :student, :presence => true

  def to_label
    "#{enrollment_number} - #{student.name}"
  end

  def available_semesters
    self.class_enrollments.joins(course_class: :course)
      .group('course_classes.year', 'course_classes.semester')
      .order('course_classes.year', 'course_classes.semester')
      .select(['course_classes.year', 'course_classes.semester']).collect { |y| [y.year, y.semester] }
  end

  def gpr_by_semester(year, semester)
    result = self.class_enrollments.joins(course_class: {course: :course_type})
      .where(
        'course_classes.year' => year, 
        'course_classes.semester' => semester, 
        'course_types.has_score' => true)
      .where(ClassEnrollment.arel_table[:situation].not_eq(I18n.translate("activerecord.attributes.class_enrollment.situations.registered")))
      .select('sum(credits*grade) as grade, sum(credits) as credits')
    result[0]['grade'].to_f / result[0]['credits'].to_f unless result[0]['credits'].nil? or result[0]['credits'] == 0
    #In Rails 4, replace the second where with
    #where.not('class_enrollments.situation' => I18n.translate("activerecord.attributes.class_enrollment.situations.registered"))
  end

  def total_gpr
    result = self.class_enrollments.joins(course_class: {course: :course_type})
      .where('course_types.has_score' => true)
      .where(ClassEnrollment.arel_table[:situation].not_eq(I18n.translate("activerecord.attributes.class_enrollment.situations.registered")))
      .select('sum(credits*grade) as grade, sum(credits) as credits')
    result[0]['grade'].to_f / result[0]['credits'].to_f unless result[0]['credits'].nil? or result[0]['credits'] == 0
     #In Rails 4, replace the second where with
    #where.not('class_enrollments.situation' => I18n.translate("activerecord.attributes.class_enrollment.situations.registered"))
  end

  def self.with_delayed_phases_on(date, phases)
    date = Date.today if date.nil?
    phases = Phase.all if phases.nil?

    active_enrollments = Enrollment.where("enrollments.id not in (select enrollment_id from dismissals where DATE(dismissals.date) <= DATE(?))", date)

    delayed_enrollments = []

    active_enrollments.each do |enrollment|

      accomplished_phases = Accomplishment.where(:enrollment_id => enrollment, :phase_id => phases).map { |ac| ac.phase }
      phases_duration = PhaseDuration.where("level_id = :level_id and phase_id in (:phases)", :level_id => enrollment.level_id, :phases => (phases - accomplished_phases))

      begin_ys = YearSemester.on_date(enrollment.admission_date)

      phases_duration.each do |phase_duration|

        phase_duration_deadline_ys = begin_ys + phase_duration.deadline_semesters
        phases_duration_deadline_months = phase_duration.deadline_months
        phases_duration_deadline_days = phase_duration.deadline_days

        deferral_types = DeferralType.joins(:deferrals).where("deferrals.enrollment_id = :enrollment_id and phase_id = :phase_id", :enrollment_id => enrollment.id, :phase_id => phase_duration.phase_id)

        final_ys = phase_duration_deadline_ys
        final_months = phases_duration_deadline_months
        final_days = phases_duration_deadline_days

        deferral_types.each do |deferral_type|
          final_ys.increase_semesters(deferral_type.duration_semesters)
          final_months += deferral_type.duration_months
          final_days += deferral_type.duration_days
        end

        deadline_date = final_ys.semester_begin + final_months.months + final_days.days
        if deadline_date <= date
          delayed_enrollments << enrollment.id
          break
        end
      end
    end
    delayed_enrollments
  end

  def self.with_all_phases_accomplished_on(date)
    enrollments = Enrollment.all
    enrollments_with_all_phases_accomplished = []
    enrollments.each do |enrollment|
      accomplished_phases = Accomplishment.where("enrollment_id = :enrollment_id and DATE(conclusion_date) <= DATE(:conclusion_date)", :enrollment_id => enrollment.id, :conclusion_date => date).map { |ac| ac.phase }
      phases_duration = PhaseDuration.where("level_id = :level_id", :level_id => enrollment.level_id).scoped
      phases_duration = phases_duration.where("phase_id not in (:accomplished_phases)", :accomplished_phases => accomplished_phases) unless accomplished_phases.blank?
      enrollments_with_all_phases_accomplished << enrollment.id if phases_duration.blank?
    end
    enrollments_with_all_phases_accomplished
  end

end

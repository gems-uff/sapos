# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Enrollment < ActiveRecord::Base
  attr_accessible :enrollment_number, :admission_date, :obs, :thesis_title, 
    :thesis_defense_date

  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
  belongs_to :research_area

  has_many :professors, :through => :advisements, :readonly => false
  has_many :scholarships, :through => :scholarship_durations
  has_many :phases, :through => :accomplishments

  has_one :dismissal, :dependent => :restrict
  has_many :advisements, :dependent => :destroy
  has_many :scholarship_durations, :dependent => :destroy
  has_many :accomplishments, :dependent => :destroy
  has_many :deferrals, :dependent => :destroy
  has_many :class_enrollments, :dependent => :destroy
  has_many :thesis_defense_committee_participations, :dependent => :destroy
  has_many :thesis_defense_committee_professors, :source => :professor, :through => :thesis_defense_committee_participations
  has_many :phase_completions, :dependent => :destroy
  
  has_paper_trail

  validates :enrollment_number, :presence => true, :uniqueness => true
  validates :level, :presence => true
  validates :enrollment_status, :presence => true
  validates :student, :presence => true

  validate :enrollment_has_main_advisor

  validates_date :thesis_defense_date, :on_or_after => :admission_date, :allow_nil => true, :on_or_after_message => I18n.t("activerecord.errors.models.enrollment.thesis_defense_date_before_admission_date")

  validate :verify_research_area_with_advisors

  after_save :create_phase_completions

  def to_label
    return enrollment_number if student.nil?
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


  def enrollment_has_main_advisor
    unless advisements.nil? or advisements.empty?
      #found = false
      main_advisors = 0
      advisements.each do |a|
        #found ||= a.main_advisor
        main_advisors += 1 if a.main_advisor
      end
      errors.add(:base, I18n.translate("activerecord.errors.models.enrollment.main_advisor_required")) if main_advisors == 0
      errors.add(:base, I18n.translate("activerecord.errors.models.enrollment.main_advisor_uniqueness")) if main_advisors > 1

      
    end
  end

  def verify_research_area_with_advisors
    unless advisements.nil? or advisements.empty? or research_area.nil?
      research_areas = []
      advisements.each do |advisement|
        research_areas += advisement.professor.research_areas unless advisement.professor.research_areas.nil?
      end
      unless research_areas.include? research_area
        errors.add(:research_area, I18n.translate("activerecord.errors.models.enrollment.research_area_different_from_professors"))
      end
    end
  end

  def create_phase_completions()
    PhaseCompletion.where(:enrollment_id => id).destroy_all

    PhaseDuration.where(:level_id => level_id).each do |phase_duration|
      completion_date = nil

      phase_accomplishment = accomplishments.where(:phase_id => phase_duration.phase_id)[0]
      completion_date = phase_accomplishment.conclusion_date unless phase_accomplishment.nil?

      phase_deferrals = deferrals.select { |deferral| deferral.deferral_type.phase == phase_duration.phase}
      if phase_deferrals.empty?
        due_date = phase_duration.phase.calculate_end_date(admission_date, phase_duration.deadline_semesters, phase_duration.deadline_months, phase_duration.deadline_days)
      else
        total_time = phase_duration.phase.calculate_total_deferral_time_for_phase_until_date(self, Date.today)
        due_date = phase_duration.phase.calculate_end_date(admission_date, total_time[:semesters], total_time[:months], total_time[:days])
      end

      PhaseCompletion.create(:enrollment_id=>id, :phase_id=>phase_duration.phase.id, :completion_date=>completion_date, :due_date=>due_date)
    end
  end
end

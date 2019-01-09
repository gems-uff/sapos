# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Enrollment < ApplicationRecord

  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
  belongs_to :research_area

  attr_readonly :professors
  
  has_one :dismissal, :dependent => :restrict_with_exception
  has_many :advisements, :dependent => :destroy
  has_many :professors, :through => :advisements
  has_many :scholarship_durations, :dependent => :destroy
  has_many :scholarships, :through => :scholarship_durations
  has_many :accomplishments, :dependent => :destroy
  has_many :phases, :through => :accomplishments
  has_many :deferrals, :dependent => :destroy
  has_many :enrollment_holds, :dependent => :destroy
  has_many :class_enrollments, :dependent => :destroy
  has_many :thesis_defense_committee_participations, :dependent => :destroy
  has_many :thesis_defense_committee_professors, :source => :professor, :through => :thesis_defense_committee_participations
  has_many :phase_completions, :dependent => :destroy
  
  has_paper_trail

  validates :enrollment_number, :presence => true, :uniqueness => true
  validates :level, :presence => true
  validates :enrollment_status, :presence => true
  validates :student, :presence => true
  validates_associated :dismissal
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
    phases_ids = phases.map(&:id)

    Enrollment.joins(:phase_completions).includes(:dismissal)
      .where(:phase_completions => {
        :completion_date => nil,
        :phase_id => phases_ids

      })
      .where(PhaseCompletion.arel_table[:due_date].lt(date))
      .where(
        Dismissal.arel_table[:date].gt(date)
        .or(Dismissal.arel_table[:enrollment_id].eq(nil))
      ).references(:dismissals).map(&:id).uniq
  end

  def delayed_phases(options={})
    date ||= options[:date]
    date ||= Date.today
    self.phase_completions
      .where(PhaseCompletion.arel_table[:due_date].lt(date))
      .where(:completion_date => nil).collect{|pc| pc.phase}
  end

  def self.with_all_phases_accomplished_on(date)
    enrollments = Enrollment.all
    enrollments_with_all_phases_accomplished = []
    enrollments.each do |enrollment|
      accomplished_phases = Accomplishment.where("enrollment_id = :enrollment_id and DATE(conclusion_date) <= DATE(:conclusion_date)", :enrollment_id => enrollment.id, :conclusion_date => date).map { |ac| ac.phase }
      phases_duration = PhaseDuration.where("level_id = :level_id", :level_id => enrollment.level_id)
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

  def create_phase_completions
    PhaseCompletion.where(:enrollment_id => id).destroy_all

    PhaseDuration.where(:level_id => level_id).each do |phase_duration|
      PhaseCompletion.new(
        :enrollment=>self, 
        :phase=>phase_duration.phase
      ).save
    end
  end
end

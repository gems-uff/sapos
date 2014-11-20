#encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhaseDuration < ActiveRecord::Base
  attr_accessible :deadline_semesters, :deadline_months, :deadline_days

  belongs_to :phase
  belongs_to :level

  has_paper_trail

  validates :phase, :presence => true
  validates :level, :presence => true

  validate :deadline_validation


  before_destroy :validate_destroy
  after_commit :create_phase_completions

  def to_label
    "#{deadline_semesters} períodos, #{deadline_months} meses e #{deadline_days} dias"
  end

  def deadline_validation
    if (([0,nil].include?(self.deadline_semesters)) && ([0,nil].include?(self.deadline_months)) && ([0,nil].include?(self.deadline_days)))
      errors.add(:deadline, I18n.t("activerecord.errors.models.phase_duration.blank_deadline"))
    end
  end

  def duration
    {:semesters => self.deadline_semesters, :months => self.deadline_months, :days => self.deadline_days}
  end


  def validate_destroy
    return true if phase.nil? or level.nil?
    has_deferral = phase.deferral_type.any? do |deferral_type|
      deferral_type.deferrals.any? do |deferral|
        deferral.enrollment.level == level
      end
    end
    has_level = level.enrollments.any? do |enrollment| 
      enrollment.accomplishments.any? do |accomplishment|
        accomplishment.phase == phase
      end
    end
    if has_deferral
      errors.add(:base, I18n.t("activerecord.errors.models.phase_duration.has_deferral"))
      phase.errors.add(:base, I18n.t("activerecord.errors.models.phase.phase_duration_has_deferral", :level => level.to_label))
    end
    if has_level
      errors.add(:base, I18n.t("activerecord.errors.models.phase_duration.has_level"))
      phase.errors.add(:base, I18n.t("activerecord.errors.models.phase.phase_duration_has_level", :level => level.to_label))
    end
    !has_deferral and !has_level
  end

  def create_phase_completions
    PhaseCompletion.joins(:enrollment).where(:phase_id => phase.id, :enrollments => {:level_id => level.id}).destroy_all
    
    Enrollment.where(:level_id => level_id).each do |enrollment|
      PhaseCompletion.new(
        :enrollment=>enrollment, :phase=>phase
      ).save
    end
  end
end

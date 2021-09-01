# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Accomplishment < ApplicationRecord
  belongs_to :enrollment
  belongs_to :phase

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :phase_id, :message => :accomplishment_enrollment_uniqueness}
  validates :phase, :presence => true

  validate :enrollment_level

  validates :conclusion_date, :presence => true

  after_commit :update_completion_date

  after_create :notify_student_and_advisor

  def to_label
    "#{phase.name}"    
  end

  def update_completion_date
  	phase_completion = PhaseCompletion.where(:enrollment_id => enrollment_id, :phase_id => phase_id).first
  	if phase_completion
  	  phase_completion.calculate_completion_date
  	  phase_completion.save
  	end
  end
  
  def enrollment_level
    return if enrollment.nil?
    return if phase.nil?

    unless phase.levels.include? enrollment.level
      errors.add(:enrollment, I18n.translate("activerecord.errors.models.accomplishment.enrollment_level")) 
    end
  end

  def notify_student_and_advisor
    emails = [EmailTemplate.load_template("accomplishments:email_to_student").prepare_message({
      :record => self
    })]
    enrollment.advisements.each do |advisement|
      emails << EmailTemplate.load_template("accomplishments:email_to_advisor").prepare_message({
        :record => self,
        :advisement => advisement
      })
    end
    Notifier.send_emails(notifications: emails)
  end
end

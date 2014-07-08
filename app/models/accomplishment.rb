# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :phase_id, :message => :accomplishment_enrollment_uniqueness}
  validates :phase, :presence => true

  validate :enrollment_level

  after_save :set_completion_date
  after_create :notify_student_and_advisor

  def to_label
    "#{phase.name}"    
  end

  def set_completion_date
  	phase_completion = PhaseCompletion.where(:enrollment_id => enrollment_id, :phase_id => phase_id).first
  	if phase_completion
  	  phase_completion.completion_date = conclusion_date
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
    info = {
      :name => enrollment.student.name,
      :phase => phase.name,
    }
    message_to_student = {
      :to => enrollment.student.email,
      :subject => I18n.t('notifications.accomplishment.email_to_student.subject', info),
      :body => I18n.t('notifications.accomplishment.email_to_student.body', info)
    }
    emails = [message_to_student]
    enrollment.advisements.each do |advisement|
      advisor_info = info.merge(:advisor_name => advisement.professor.name)
      emails << message_to_advisor = {
        :to => advisement.professor.email,
        :subject => I18n.t('notifications.accomplishment.email_to_advisor.subject', advisor_info),
        :body => I18n.t('notifications.accomplishment.email_to_advisor.body', advisor_info)
      }
    end
    Notifier.send_emails(notifications: emails)
  end
end

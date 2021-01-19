# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Deferral < ApplicationRecord
  belongs_to :enrollment
  belongs_to :deferral_type

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :deferral_type_id, :message => :enrollment_and_deferral_uniqueness}
  validates :deferral_type, :presence => true
  validates :approval_date, :presence => true


  validate :enrollment_level

  after_commit :recalculate_due_date_for_phase_completion
  after_create :notify_student_and_advisor

  def to_label
    "#{deferral_type.name}" unless deferral_type.nil?    
  end

  def valid_until
    DateUtils.add_hash_to_date(
      enrollment.admission_date, 
      deferral_type.phase.total_duration(enrollment, until_date: approval_date)
    ).strftime('%d/%m/%Y')
  end

  def recalculate_due_date_for_phase_completion
    phase_completion = PhaseCompletion.where(:enrollment_id => enrollment_id, :phase_id => deferral_type.phase_id).first
    if phase_completion
      phase_completion.calculate_due_date
      phase_completion.save
    end
  end

  def enrollment_level
    return if enrollment.nil?
    return if deferral_type.nil?

    unless deferral_type.phase.levels.include? enrollment.level
      errors.add(:enrollment, I18n.translate("activerecord.errors.models.deferral.enrollment_level")) 
    end
  end

  def notify_student_and_advisor
    info = {
      :name => enrollment.student.name,
      :phase => deferral_type.phase.name,
      :deferral => deferral_type.name,
    }
    message_to_student = {
      :to => enrollment.student.email,
      :subject => I18n.t('notifications.deferral.email_to_student.subject', **info),
      :body => I18n.t('notifications.deferral.email_to_student.body', **info)
    }
    emails = [message_to_student]
    enrollment.advisements.each do |advisement|
      advisor_info = info.merge(:advisor_name => advisement.professor.name)
      emails << message_to_advisor = {
        :to => advisement.professor.email,
        :subject => I18n.t('notifications.deferral.email_to_advisor.subject', advisor_info),
        :body => I18n.t('notifications.deferral.email_to_advisor.body', advisor_info)
      }
    end
    Notifier.send_emails(notifications: emails)
  end
end

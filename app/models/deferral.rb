# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Deferral < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :deferral_type

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :deferral_type_id, :message => :enrollment_and_deferral_uniqueness}
  validates :deferral_type, :presence => true
  validates :approval_date, :presence => true


  validate :enrollment_level

  after_save :recalculate_due_date_for_phase_completion
  after_create :notify_student_and_advisor

  def to_label
    "#{deferral_type.name}" unless deferral_type.nil?    
  end

  def total_time_with_deferrals
    durations = deferral_type.phase.phase_durations
    phase_duration = durations.select { |duration| duration.level_id == enrollment.level.id}[0]

    total_time = phase_duration.duration

    deferrals = enrollment.deferrals.select { |deferral| deferral.deferral_type.phase == deferral_type.phase}
    for deferral in deferrals
      if approval_date >= deferral.approval_date
        deferral_duration = deferral.deferral_type.duration
        (total_time.keys | deferral_duration.keys).each do |key|
          total_time[key] += deferral_duration[key].to_i
        end
      end
    end

    total_time
  end

  def valid_until
    total_time = deferral_type.phase.calculate_total_deferral_time_for_phase_until_date(enrollment, approval_date)
    deferral_type.phase.calculate_end_date(enrollment.admission_date, total_time[:semesters], total_time[:months], total_time[:days]).strftime('%d/%m/%Y')
  end

  def recalculate_due_date_for_phase_completion
    phase_completion = PhaseCompletion.where(:enrollment_id => enrollment_id, :phase_id => deferral_type.phase_id).first
    if phase_completion
      phase_completion.due_date = valid_until
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
      :subject => I18n.t('notifications.deferral.email_to_student.subject', info),
      :body => I18n.t('notifications.deferral.email_to_student.body', info)
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
    Notifier.instance.send_emails(emails)
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment

  has_paper_trail

  validates :professor, :presence => true
  validates :enrollment, :presence => true

  validates :professor_id, :uniqueness => {:scope => :enrollment_id, :message => :advisement_professor_uniqueness} #A professor can't be advisor more than once of an enrollment

  after_create :notify_advisor

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"
  end
  
  #defines if an certain advisement is active (An active advisement is an advisement which the student doesn't have a dismissal reason
  def active
    return false if enrollment.nil?
    dismissals = Dismissal.where(:enrollment_id => enrollment.id)
    return dismissals.empty?
  end
 
  def active_order
    return active.to_s
  end

  def co_advisor_list
    return "" if enrollment.nil?
    return "" if professor.nil?
    professor_list = Professor.
                     joins(:advisements).
                     order("professors.name").
                     where("advisements.enrollment_id" => enrollment.id
                     ).
                     where("professors.id <> ? ",professor.id)

    return professor_list.map(&:name).join(" , ")
  end

  def co_advisor
      return false if enrollment.nil?
      co_advisors = Advisement.where(:main_advisor => false, :enrollment_id => enrollment.id)
      return !co_advisors.empty?
  end
  
  def co_advisor_order
    return co_advisor.to_s
  end
  
  def enrollment_number
    return nil if enrollment.nil?
    return enrollment.enrollment_number
  end
  
  def student_name
    return nil if enrollment.nil?
    return nil if enrollment.student.nil?
    return enrollment.student.name
  end
  
  def enrollment_has_advisors
    return false if enrollment.nil?
    enrollment_advisements = Advisement.where(:enrollment_id => enrollment.id)
    return false if enrollment_advisements.empty?
    !enrollment_advisements.where(main_advisor: true).empty?
  end

  def notify_advisor
    advisor_info = {
      :name => enrollment.student.name,
      :advisor_name => professor.name
    }
    emails = [{
      :to => professor.email,
      :subject => I18n.t('notifications.advisement.email_to_advisor.subject', advisor_info),
      :body => I18n.t('notifications.advisement.email_to_advisor.body', advisor_info)
    }]
    Notifier.send_emails(notifications: emails)
  end

end

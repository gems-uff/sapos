# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Enrollment < ActiveRecord::Base
  attr_accessible :enrollment_number, :thesis_title
  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status

  has_many :professors, :through => :advisements, :readonly => false
  has_many :scholarships, :through => :scholarship_durations
  has_many :phases, :through => :accomplishments

  has_one :dismissal, :dependent => :destroy
  has_many :advisements, :dependent => :destroy
  has_many :scholarship_durations, :dependent => :destroy
  has_many :accomplishments, :dependent => :destroy
  has_many :deferrals, :dependent => :destroy
  has_many :class_enrollments, :dependent => :destroy

  has_paper_trail

  validates :enrollment_number, :presence => true, :uniqueness => true
  validates :level, :presence => true
  validates :enrollment_status, :presence => true
  validates :student, :presence => true

  validate :enrollment_has_main_advisor

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

# TODO Alocate all methods to a helper.
  def listed_advisors
    return "-" if self.advisements.empty? 
    
    body = ""
    count = 0

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Nome do Orientador</td>
                <th>Matrícula do Orientador</td>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    self.advisements.each do |advisement|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      if advisement.main_advisor
        body += "<tr class=\"record #{tr_class}\">
                  <td><strong>#{advisement.professor.name}</strong></td>
                  <td><strong>#{advisement.professor.enrollment_number}</strong></td>
                </tr>"
      else
        body += "<tr class=\"record #{tr_class}\">
                  <td>#{advisement.professor.name}</td>
                  <td>#{advisement.professor.enrollment_number}</td>
                </tr>"
      end
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def listed_accomplishments
    return "-" if self.accomplishments.empty?

    body = ""
    count = 0

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Etapa</td>
                <th>Data de Conclusão</td>
                <th>Observação</td>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    self.accomplishments.each do |accomplishment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{accomplishment.phase.name}</td>
                <td>#{accomplishment.conclusion_date}</td>
                <td>#{accomplishment.obs}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def listed_deferrals
    return "-" if self.deferrals.empty?
    
    body = ""
    count = 0

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Data de Aprovação</td>
                <th>Observação</td>
                <th>Tipo de Prorrogação</td>
              </tr>
            </thead>"
    
    body += "<tbody class=\"records\">"

    self.deferrals.each do |deferral|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{deferral.approval_date}</td>
                <td>#{deferral.obs}</td>
                <td>#{deferral.deferral_type.name}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def listed_scholarships
    return "-" if self.scholarships.empty?
    
    body = ""
    count = 0

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Número da Bolsa</td>
                <th>Data de início</td>
                <th>Data limite de concessão</td>
                <th>Data de encerramento</td>
                <th>Observação</td>
              </tr>
            </thead>"

    body += "<tbody class=\"records\">"
            
    self.scholarships.each do |scholarship|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{scholarship.scholarship_number}</td>
                <td>#{scholarship.start_date}</td>
                <td>#{scholarship.end_date}</td>
                <td>#{scholarship.scholarship_durations.where(:cancel_date => nil).empty? ? "-" : scholarship.scholarship_durations.where(:cancel_date => nil).last.end_date}</td>
                <td>#{scholarship.obs}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def listed_class_enrollments
    return "-" if self.class_enrollments.empty?
    
    body = ""
    count = 0

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Turma</td>
                <th>Situação</td>
                <th>Nota</td>
                <th>Reprovado por falta</td>
                <th>Observação</td>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    self.class_enrollments.each do |class_enrollment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{class_enrollment.course_class_id}</td>
                <td>#{class_enrollment.situation}</td>
                <td>#{class_enrollment.grade}</td>"

      if class_enrollment.attendance_to_label == "N"                                                                                       
        body += "<td>Sim</td>"
      else
        body += "<td>Não</td>"
      end

      body += "<td>#{class_enrollment.obs}</td>
             </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end
end

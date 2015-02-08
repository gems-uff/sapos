class EnrollmentHold < ActiveRecord::Base
  belongs_to :enrollment
  attr_accessible :number_of_semesters, :semester, :year

  has_paper_trail

  validates :enrollment, :presence => true
  validates :number_of_semesters, :numericality => {:greater_than_or_equal_to => 1}, :presence => true
  validates :semester, :inclusion => [1, 2], :presence => true
  validates :year, :presence => true

  validate :validate_dates

  after_commit :create_phase_completions

  def to_label
    "#{date_label} - #{number_label}"
  end

  def date_label
    "#{year}.#{semester}"
  end

  def number_label
    "#{number_of_semesters} #{I18n.t("activerecord.attributes.enrollment_hold.number_label").pluralize(number_of_semesters)}"
  end

  def validate_dates
    return if enrollment.nil? or year.nil? or semester.nil?
    admission_date = enrollment.admission_date
    if self.start_date < admission_date
      errors.add(:base, I18n.t("activerecord.errors.models.enrollment_hold.before_admission_date"))      
    end
    dismissal = enrollment.dismissal
    if !dismissal.nil? and self.end_date > dismissal.date
      errors.add(:base, I18n.t("activerecord.errors.models.enrollment_hold.after_dismissal_date"))      
    end
  end

  def start_date
    ys = YearSemester.new :year => year, :semester => semester
    ys.semester_begin
  end

  def end_date
    ys = YearSemester.new :year => year, :semester => semester
    (ys + (number_of_semesters - 1)).semester_end
  end

  def create_phase_completions
    enrollment.create_phase_completions
  end
end

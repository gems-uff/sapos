class ClassSchedule < ApplicationRecord

  has_paper_trail

  validates :year, :presence => true
  validates :semester, :presence => true, :inclusion => {:in => YearSemester::SEMESTERS}
  validates_uniqueness_of :semester, :scope => [:year]
  validates :enrollment_start, :presence => true
  validates :enrollment_end, :presence => true

  def to_label
    "#{year}.#{semester}"
  end

end

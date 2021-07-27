class ClassSchedule < ApplicationRecord

  has_paper_trail

  SEMESTERS = [1,2]

  validates :year, :presence => true
  validates :semester, :presence => true, :inclusion => {:in => SEMESTERS}
  validates_uniqueness_of :semester, :scope => [:year]
  validates :enrollment_start, :presence => true
  validates :enrollment_end, :presence => true


end

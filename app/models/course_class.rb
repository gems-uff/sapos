class CourseClass < ActiveRecord::Base
  belongs_to :course
  belongs_to :professor

  has_many :class_enrollments, :dependent => :destroy
  has_many :allocations, :dependent => :destroy

  SEMESTERS = [1,2]

  validates :course, :presence => true
  validates :professor, :presence => true
  validates :year, :presence => true
  validates :semester, :presence => true, :inclusion => {:in => SEMESTERS}

  def to_label
    "#{name || course.name} - #{year}/#{semester}"
  end
end

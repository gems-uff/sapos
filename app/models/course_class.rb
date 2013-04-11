class CourseClass < ActiveRecord::Base
  belongs_to :course
  belongs_to :professor

  has_many :class_enrollments
  has_many :allocations

  validates :course, :presence => true
  validates :professor, :presence => true
  validates :year, :presence => true
  validates :semester, :presence => true

  def to_label
    "#{name || course.name} - #{year}/#{semester}"
  end
end

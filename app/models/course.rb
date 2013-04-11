class Course < ActiveRecord::Base
  belongs_to :research_area
  belongs_to :course_type

  validates :course_type, :presence => true
  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true
  validates :credits, :presence => true
end

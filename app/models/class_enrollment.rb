class ClassEnrollment < ActiveRecord::Base
  belongs_to :course_class
  belongs_to :enrollment
end

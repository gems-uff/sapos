class Professor < ActiveRecord::Base
  has_many :advisements
  has_many :enrollments, :through => :advisements
end
class Professor < ActiveRecord::Base
  has_many :advisements, :dependent => :destroy
  has_many :enrollments, :through => :advisements
  has_many :scholarships, :dependent => :destroy
end
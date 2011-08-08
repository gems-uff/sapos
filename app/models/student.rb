class Student < ActiveRecord::Base
  has_and_belongs_to_many :courses
  #delete cascade for enrollment -- when a student is deleted, so are his enrollments
  has_many :enrollments, :dependent => :destroy
  
  validates :name, :presence => true
  validates :cpf, :presence => true, :uniqueness => true
  
end

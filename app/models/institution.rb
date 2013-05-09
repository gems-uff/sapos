class Institution < ActiveRecord::Base
  has_many :majors, :dependent => :destroy
  
  validates :name, :presence => true, :uniqueness => true
end
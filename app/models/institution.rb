class Institution < ActiveRecord::Base
  has_many :courses, :dependent => :destroy
  
  validates :name, :presence => true, :uniqueness => true
end
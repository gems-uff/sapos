class Country < ActiveRecord::Base
  has_many :state
  
  validates :name, :presence => true, :uniqueness => true
end

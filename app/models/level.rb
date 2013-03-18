class Level < ActiveRecord::Base
  has_many :advisement_authorizations
  validates :name, :presence => true, :uniqueness => true
end

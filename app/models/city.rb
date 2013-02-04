class City < ActiveRecord::Base
  belongs_to :state

  validates :state, :presence => true

  validates :name, :presence => true
end

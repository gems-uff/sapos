class Phase < ActiveRecord::Base
  has_many :accomplishments, :dependent => :destroy
  has_many :enrollments, :through => :accomplishments
  has_many :phase_durations, :dependent => :destroy
  has_many :levels, :through => :phase_durations
  
  validates :name, :presence => true  
end

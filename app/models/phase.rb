class Phase < ActiveRecord::Base
  has_many :accomplishments, :dependent => :destroy
  has_many :enrollments, :through => :accomplishments
  belongs_to :level
end

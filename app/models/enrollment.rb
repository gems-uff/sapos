class Enrollment < ActiveRecord::Base
  belongs_to :student
  belongs_to :level
  belongs_to :enrollment_status
  has_one :dismissal, :dependent => :destroy
  has_many :advisements, :dependent => :destroy
  has_many :professors, :through => :advisements
  has_many :scholarship_durations, :dependent => :destroy
  has_many :scholarships, :through => :scholarship_durations
  has_many :accomplishments, :dependent => :destroy
  has_many :phases, :through => :accomplishments
  has_many :deferrals, :dependent => :destroy
    
  def to_label
    "#{enrollment_number} - #{student.name}"
  end
  
  validates :enrollment_number, :presence => true, :uniqueness => true
  validates :level, :presence => true
  validates :enrollment_status, :presence => true  
  validates :student, :presence => true
end

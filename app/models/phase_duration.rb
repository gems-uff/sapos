class PhaseDuration < ActiveRecord::Base
  belongs_to :phase
  belongs_to :level
  
  def to_label
    "#{deadline}"
  end
  
  validates :deadline, :numericality => true
end

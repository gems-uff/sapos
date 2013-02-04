class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase

  validates :enrollment, :presence => true
  validates :phase, :presence => true

  def to_label
    "#{phase.name}"    
  end
  
end

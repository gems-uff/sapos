class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase
  
  def to_label
    "#{phase.name}"    
  end
  
end

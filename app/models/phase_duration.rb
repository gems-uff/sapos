class PhaseDuration < ActiveRecord::Base
  belongs_to :phase
  belongs_to :level
end

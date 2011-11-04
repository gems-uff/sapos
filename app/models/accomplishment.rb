class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase
end

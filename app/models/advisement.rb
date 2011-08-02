class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment
end

class Course < ActiveRecord::Base
  belongs_to :level
  belongs_to :institution
end

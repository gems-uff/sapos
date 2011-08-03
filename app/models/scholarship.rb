class Scholarship < ActiveRecord::Base
  belongs_to :level
  belongs_to :sponsor
  belongs_to :scholarship_type
end

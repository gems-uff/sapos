class ScholarshipDuration < ActiveRecord::Base
  belongs_to :scholarship
  belongs_to :enrollment
end

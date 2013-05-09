class ProfessorResearchArea < ActiveRecord::Base
  belongs_to :professor
  belongs_to :research_area
end

class ResearchArea < ActiveRecord::Base
  has_many :courses
  has_many :professors, :through => :professor_research_areas

  validates :name, :presence => true
  validates :code, :presence => true

  def to_label
    "#{code} - #{name}"
  end
end

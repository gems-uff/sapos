class ResearchArea < ActiveRecord::Base
  has_many :courses
  has_many :professors, :through => :professor_research_areas

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

  def to_label
    "#{code} - #{name}"
  end
end

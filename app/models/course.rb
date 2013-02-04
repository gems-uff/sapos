class Course < ActiveRecord::Base
  belongs_to :level
  belongs_to :institution
  has_and_belongs_to_many :students, :join_table => "courses_students"

  validates :name, :presence => true
  validates :institution, :presence => true
  validates :level, :presence => true

  def to_label
    "#{name} - #{institution.name} - (#{level.name})"
  end
end
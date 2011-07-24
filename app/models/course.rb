class Course < ActiveRecord::Base
  belongs_to :level
  belongs_to :institution
#  has_and_belongs_to_many :students

  def to_label
    #"#{institution.name} - #{name} (#{level.name})"
    "#{name} (#{level.name})"
  end
end
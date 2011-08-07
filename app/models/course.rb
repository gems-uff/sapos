class Course < ActiveRecord::Base
  belongs_to :level
  belongs_to :institution
#  has_and_belongs_to_many :students

  def to_label
    "#{name} - #{institution.name} - (#{level.name})"    
  end
end
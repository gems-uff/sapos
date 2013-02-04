class Dismissal < ActiveRecord::Base
  belongs_to :dismissal_reason
  belongs_to :enrollment

  validates :date, :presence => true
  validates :dismissal_reason, :presence => true
  validates :enrollment, :presence => true

  def to_label
    #"#{date.day}-#{date.month}-#{date.year}"    
    "#{date}"    
  end
  
end

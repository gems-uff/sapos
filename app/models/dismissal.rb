class Dismissal < ActiveRecord::Base
  belongs_to :dismissal_reason
  belongs_to :enrollment
  
  def to_label
    #"#{date.day}-#{date.month}-#{date.year}"    
    "#{date}"    
  end
  
  validates :dismissal_reason, :presence => true
  validates :date, :presence => true
  validates :enrollment, :presence => true
end

class Dismissal < ActiveRecord::Base
  belongs_to :dismissal_reason
  
  def to_label
    "#{date}"
  end
  
  validates :dismissal_reason, :presence => true
  validates :date, :presence => true
end

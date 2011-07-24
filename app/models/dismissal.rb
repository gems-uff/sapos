class Dismissal < ActiveRecord::Base
  belongs_to :dismissal_reason
  
  def to_label
    "#{date}"
  end
end

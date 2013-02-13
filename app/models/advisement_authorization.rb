class AdvisementAuthorization < ActiveRecord::Base
  belongs_to :professor
  belongs_to :level

  validates :professor, :presence => true
  validates :level, :presence => true

  def to_label
    "#{level.name}"
  end
  
end

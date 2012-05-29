class DeferralType < ActiveRecord::Base
  belongs_to :phase
  
  validates :duration ,:numericality => true
  validates :name, :presence => true
end

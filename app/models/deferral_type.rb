class DeferralType < ActiveRecord::Base
  belongs_to :phase
  
  validates :duration, :presence => true,:numericality => true
  validates :name, :presence => true
end

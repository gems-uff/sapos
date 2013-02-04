class DeferralType < ActiveRecord::Base
  belongs_to :phase
  has_many :deferrals

  validates :duration_semesters ,:numericality => true
  validates :duration_months ,:numericality => true
  validates :duration_days ,:numericality => true
  validates :name, :presence => true
  validates :phase, :presence => true
end

class PhaseDuration < ActiveRecord::Base
  belongs_to :phase
  belongs_to :level

  validates :deadline_semesters, :numericality => true
  validates :deadline_months, :numericality => true
  validates :deadline_days, :numericality => true

  validates :phase, :presence => true
  validates :level, :presence => true

  def to_label
    "#{deadline_semesters} períodos, #{deadline_months} meses e #{deadline_days} dias"
  end
end

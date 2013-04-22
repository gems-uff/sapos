class PhaseDuration < ActiveRecord::Base
  belongs_to :phase
  belongs_to :level

  validates :phase, :presence => true
  validates :level, :presence => true

  validate :deadline_validation

  def to_label
    "#{deadline_semesters} períodos, #{deadline_months} meses e #{deadline_days} dias"
  end

  def deadline_validation
    if (([0,nil].include?(self.deadline_semesters)) && ([0,nil].include?(self.deadline_months)) && ([0,nil].include?(self.deadline_days)))
      errors.add(:deadline, I18n.t("activerecord.errors.models.phase_duration.blank_deadline"))
    end
  end
end

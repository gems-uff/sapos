class Advisement < ActiveRecord::Base
  belongs_to :professor
  belongs_to :enrollment

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"    
  end
  
  validate :one_main_advisor_per_enrollment
  
  def one_main_advisor_per_enrollment    
    old_main_advisement = Advisement.find_by_sql(["select * from advisements where enrollment_id = ? and main_advisor = 1",enrollment.id]) unless enrollment.nil?
    errors.add(:enrollment,I18n.t("activerecord.errors.advisement.already_with_main_advisor")) if (not old_main_advisement.empty? and main_advisor)
  end
end

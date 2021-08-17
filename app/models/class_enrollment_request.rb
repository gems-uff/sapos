class ClassEnrollmentRequest < ApplicationRecord
  belongs_to :enrollment_request
  belongs_to :course_class
  
  has_paper_trail

  REGISTERED = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.registered")
  APPROVED = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.aproved")
  DISAPPROVED = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.disapproved")
  STATUSES = [REGISTERED, APPROVED, DISAPPROVED]

  validates :enrollment_request, :presence => true
  validates :course_class, :presence => true
  validates :status_professor, :presence => true, :inclusion => {:in => STATUSES}
  validates :status_coord, :presence => true, :inclusion => {:in => STATUSES}

end

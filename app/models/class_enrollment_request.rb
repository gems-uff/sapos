class ClassEnrollmentRequest < ApplicationRecord
  belongs_to :enrollment_request, inverse_of: :class_enrollment_requests
  belongs_to :course_class
  belongs_to :class_enrollment, optional: true
  
  has_paper_trail

  REQUESTED = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.requested")
  VALID = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.valid")
  INVALID = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.invalid")
  EFFECTED = I18n.translate("activerecord.attributes.class_enrollment_request.statuses.effected")
  STATUSES = [INVALID, REQUESTED, VALID, EFFECTED]
  STATUSES_PRIORITY = [EFFECTED, VALID, INVALID, REQUESTED] 

  validates :enrollment_request, :presence => true
  validates :course_class, :presence => true
  validates :status, :presence => true, :inclusion => {:in => STATUSES}
  validates_uniqueness_of :course_class, :scope => [:enrollment_request]
  validates :class_enrollment, :presence => true, if: -> { status == EFFECTED }
  validate :validate_class_enrollment_match

  after_save :update_main_request_status_on_save
  after_create :update_main_request_status_on_create
  after_destroy :update_main_request_status_on_destroy

  protected

  def validate_class_enrollment_match
    ce = self.class_enrollment
    return if ce.nil?
    if ce.course_class_id != self.course_class_id || ce.enrollment_id != self.enrollment_request.enrollment_id
      errors.add(:class_enrollment, :must_represent_the_same_enrollment_and_class)
    end
  end

  def update_main_request_status_on_save
    if saved_change_to_attribute?(:status) && (self.status == EFFECTED || self.status_before_last_save == EFFECTED)
      self.enrollment_request.refresh_status!
    end
  end

  def update_main_request_status_on_create
    if self.status != EFFECTED && self.enrollment_request.status == EFFECTED
      self.enrollment_request.refresh_status!
    end
  end

  def update_main_request_status_on_destroy
    if self.status != EFFECTED && self.enrollment_request.status != EFFECTED
      self.enrollment_request.refresh_status!
    end
  end

end

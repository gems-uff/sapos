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
  STATUSES_MAP = {
    INVALID => :invalid,
    REQUESTED => :requested,
    VALID => :valid,
    EFFECTED => :effected
  }

  validates :enrollment_request, :presence => true
  validates :course_class, :presence => true
  validates_uniqueness_of :course_class, :scope => [:enrollment_request]
  validates :status, :presence => true, :inclusion => {:in => STATUSES}
  validates :class_enrollment, :presence => true, if: -> { status == EFFECTED }
  validate :validate_class_enrollment_match
  validate :validate_course_class_duplication
  validate :validate_allocation_match

  after_save :update_main_request_status_on_save
  after_destroy :update_main_request_status_on_destroy

  def self.pendency_condition(user=nil)
    user ||= current_user
    return ["id = -1"] if user.nil?
    cer = ClassEnrollmentRequest.arel_table.dup
    cer.table_alias = 'cer'
    check_status = cer.where(
      cer[:status].not_eq(ClassEnrollmentRequest::EFFECTED)
      .and(cer[:status].not_eq(ClassEnrollmentRequest::INVALID))
    )
    if user.role_id == Role::ROLE_COORDENACAO || user.role_id == Role::ROLE_SECRETARIA
      return [
        "id IN (#{check_status.project(cer[:id]).to_sql})",
      ]
    end
    ["id = -1"]
  end

  def allocations
    return "" unless course_class = self.course_class
    course_class.allocations.collect do |allocation|
      "#{allocation.day} (#{allocation.start_time}-#{allocation.end_time})"
    end.join("; ")
  end

  def professor
    return nil unless course_class = self.course_class
    course_class.professor.to_label if course_class.professor
  end

  def parent_status
    return nil unless enrollment_request = self.enrollment_request
    enrollment_request.status
  end

  def to_effected
    changed = false
    if self.class_enrollment.nil?
      self.class_enrollment = ClassEnrollment.new(
        enrollment: self.enrollment_request.enrollment,
        course_class: self.course_class,
        situation: ClassEnrollment::REGISTERED
      )
      changed ||= true
    end
    if self.status != EFFECTED
      self.status = EFFECTED
      changed ||= true
    end
    changed
  end

  protected

  def validate_class_enrollment_match
    ce = self.class_enrollment
    return if ce.nil?
    if ce.course_class_id != self.course_class_id || ce.enrollment_id != self.enrollment_request.enrollment_id
      errors.add(:class_enrollment, :must_represent_the_same_enrollment_and_class)
    end
  end

  def validate_course_class_duplication
    enrollment_request = self.enrollment_request
    course_class = self.course_class
    return if enrollment_request.nil? || course_class.nil?
    enrollment = self.enrollment_request.enrollment
    return if enrollment.nil?
    enrollment.class_enrollments.each do |class_enrollment|
      if class_enrollment.course_class_id == self.course_class_id
        if ! course_class.course.course_type.allow_multiple_classes && class_enrollment.situation != ClassEnrollment::DISAPPROVED 
          errors.add(:course_class, :previously_approved)
        end
      end
    end
  end

  def validate_allocation_match
    enrollment_request = self.enrollment_request
    course_class = self.course_class
    return if enrollment_request.nil? || course_class.nil?
    course_class.allocations.each do |allocation|
      enrollment_request.class_enrollment_requests.each do |cer|
        next if cer == self 
        cer_course_class = cer.course_class
        next if cer_course_class.nil?
        cer_course_class.allocations.each do |other|
          unless allocation.intersects(other).nil?
            errors.add(:course_class, :impossible_allocation)
            break
          end
        end
      end
    end
  end

  def update_main_request_status_on_save
    return unless enrollment_request = self.enrollment_request
    if saved_change_to_attribute?(:status) && (self.status == EFFECTED || self.status_before_last_save == EFFECTED)
      enrollment_request.refresh_status!
    elsif self.created_at == self.updated_at && enrollment_request.status == EFFECTED # new_record
      enrollment_request.refresh_status!
    end
  end

  def update_main_request_status_on_destroy
    return unless enrollment_request = self.enrollment_request
    if (self.status != EFFECTED && enrollment_request.status != EFFECTED)
      self.enrollment_request.refresh_status!
    end
  end

end

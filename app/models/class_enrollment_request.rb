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
  STATUSES_MAP = {
    INVALID => :invalid,
    REQUESTED => :requested,
    VALID => :valid,
    EFFECTED => :effected
  }

  INSERT = I18n.translate("activerecord.attributes.class_enrollment_request.actions.insert")
  REMOVE = I18n.translate("activerecord.attributes.class_enrollment_request.actions.remove")
  ACTIONS = [INSERT, REMOVE]

  validates :enrollment_request, :presence => true
  validates :course_class, :presence => true
  validates_uniqueness_of :course_class, :scope => [:enrollment_request]
  validates :status, :presence => true, :inclusion => {:in => STATUSES}
  validates :action, :presence => true, :inclusion => {:in => ACTIONS}
  validates :class_enrollment, :presence => true, if: -> { status == EFFECTED && action == INSERT }
  validates :class_enrollment, :presence => false, if: -> { status == EFFECTED && action == REMOVE }

  validate :that_class_enrollment_matches_course_and_enrollment
  validate :that_course_class_does_not_exist_in_a_class_enrollment
  validate :validate_allocation_match

  before_validation :create_or_destroy_class_enrollment, on: %i[create update]
  after_save :destroy_or_create_class_enrollment
  after_save :send_effected_email

  def self.pendency_condition(user=nil)
    user ||= current_user
    return ["0 = -1"] if user.nil?
    return ["0 = -1"] if user.cannot?(:read_pendencies, ClassEnrollmentRequest)

    cer = ClassEnrollmentRequest.arel_table.dup
    cer.table_alias = 'cer'
    check_status = cer.where(
      cer[:status].not_eq(ClassEnrollmentRequest::EFFECTED)
      .and(cer[:status].not_eq(ClassEnrollmentRequest::INVALID))
    )

    [ClassEnrollmentRequest.arel_table[:id].in(check_status.project(cer[:id])).to_sql]
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

  def set_status!(new_status)
    changed = new_status != status || 
      (new_status == EFFECTED && action == INSERT && class_enrollment.blank?) ||
      (new_status == EFFECTED && action == REMOVE && class_enrollment.present?)
    self.status = new_status
    changed && save
  end

  protected

  def that_class_enrollment_matches_course_and_enrollment
    ce = self.class_enrollment
    return if ce.blank?
    return if ce.course_class_id == self.course_class_id && ce.enrollment_id == self.enrollment_request.enrollment_id

    errors.add(:class_enrollment, :must_represent_the_same_enrollment_and_class)
  end

  def that_course_class_does_not_exist_in_a_class_enrollment
    return if action != INSERT
    return if enrollment_request.blank? || course_class.blank?
  
    enrollment = self.enrollment_request.enrollment
    return if enrollment.nil?

    course = course_class.course
    return if enrollment.class_enrollments.none? do |enrollment_class|
      enrollment_class.course_class.course_id == course.id &&
        enrollment_class != class_enrollment &&
        !course.course_type.allow_multiple_classes &&
        enrollment_class.situation != ClassEnrollment::DISAPPROVED
    end

    errors.add(:course_class, :previously_approved)
  end

  def validate_allocation_match
    return if action != INSERT
    return if enrollment_request.blank? || course_class.blank?

    course_class.allocations.each do |allocation|
      enrollment_request.class_enrollment_requests.each do |cer|
        next if cer == self
        next if cer.action != INSERT

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

  def create_or_destroy_class_enrollment
    return if status != EFFECTED

    if action == INSERT && class_enrollment.blank?
      self.class_enrollment = ClassEnrollment.new(
        enrollment: self.enrollment_request.enrollment,
        course_class: self.course_class,
        situation: ClassEnrollment::REGISTERED
      )
    end
    if action == REMOVE && class_enrollment.present? && class_enrollment.can_destroy?
      self.class_enrollment.destroy!
    end
  end

  def destroy_or_create_class_enrollment
    return if self.status == EFFECTED

    if action == INSERT && class_enrollment.present? && class_enrollment.can_destroy?
      old_status = status
      class_enrollment.destroy
      self.status = old_status
      self.class_enrollment = nil
      save
    end
    if action == REMOVE && class_enrollment.blank?
      self.class_enrollment = ClassEnrollment.new(
        enrollment: self.enrollment_request.enrollment,
        course_class: self.course_class,
        situation: ClassEnrollment::REGISTERED
      )
      save
    end
  end

  def send_effected_email
    return if status != EFFECTED || !saved_change_to_status?

    if action == INSERT
      emails = [EmailTemplate.load_template("class_enrollment_requests:email_to_student")
                              .prepare_message({ record: self })]
    else
      emails = [EmailTemplate.load_template("class_enrollment_requests:removal_email_to_student")
                             .prepare_message({ record: self })]
    end
    Notifier.send_emails(notifications: emails)
  end

end

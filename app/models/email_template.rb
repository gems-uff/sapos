# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represent a EmailTemplate for notifications
class EmailTemplate < ApplicationRecord
  has_paper_trail

  @@disable_erb_validation = false
  LIQUID = record_i18n_attr("template_types.liquid")
  ERB = record_i18n_attr("template_types.erb")

  TEMPLATE_TYPES = [LIQUID, ERB]

  validates_uniqueness_of :name, allow_blank: true
  validates :body, presence: true
  validates :to, presence: true
  validates :subject, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }, allow_blank: false
  validate :cannot_create_new_erb_template, if: -> { self.template_type == ERB } 

  BUILTIN_TEMPLATES = {
    "accomplishments:email_to_advisor" => {
      template_type: "Liquid",
      path: File.join("accomplishments", "mailer", "email_to_advisor.text.liquid"),
      subject: I18n.t("notifications.accomplishment.email_to_advisor.subject"),
      to: "{{ advisement.professor.email }}",
      variables: {
        record: AccomplishmentDrop,
        advisement: AdvisementDrop
      }
    },
    "accomplishments:email_to_student" => {
      template_type: "Liquid",
      path: File.join("accomplishments", "mailer", "email_to_student.text.liquid"),
      subject: I18n.t("notifications.accomplishment.email_to_student.subject"),
      to: "{{ record.enrollment.student.email }}",
      variables: {
        record: AccomplishmentDrop
      }
    },
    "admissions/admissions:recover_tokens" => {
      template_type: "Liquid",
      path: File.join("admissions", "admissions", "mailer", "recover_tokens.text.liquid"),
      subject: I18n.t("notifications.admissions.admissions.recover_tokens.subject"),
      to: "{{ email }}",
      variables: {
        email: :value,
        admission_applications: [Admissions::AdmissionApplicationDrop],
        url: :value,
      }
    },
    "admissions/apply:email_to_student" => {
      template_type: "Liquid",
      path: File.join("admissions", "apply", "mailer", "email_to_student.text.liquid"),
      subject: I18n.t("notifications.admissions.apply.email_to_student.subject"),
      to: "{{ record.email }}",
      variables: {
        record: Admissions::AdmissionApplicationDrop,
        admission_process: Admissions::AdmissionProcessDrop,
        admission_apply_url: :value,
      }
    },
    "admissions/apply:edit_email_to_student" => {
      template_type: "Liquid",
      path: File.join("admissions", "apply", "mailer", "edit_email_to_student.text.liquid"),
      subject: I18n.t("notifications.admissions.apply.edit_email_to_student.subject"),
      to: "{{ record.email }}",
      variables: {
        record: Admissions::AdmissionApplicationDrop,
        admission_process: Admissions::AdmissionProcessDrop,
        admission_apply_url: :value,
      }
    },
    "admissions/apply:request_letter" => {
      template_type: "Liquid",
      path: File.join("admissions", "apply", "mailer", "request_letter.text.liquid"),
      subject: I18n.t("notifications.admissions.apply.request_letter.subject"),
      to: "{{ letter_request.email }}",
      variables: {
        record: Admissions::AdmissionApplicationDrop,
        admission_process: Admissions::AdmissionProcessDrop,
        letter_request: Admissions::LetterRequestDrop,
        fill_letter_url: :value
      }
    },
    "advisements:email_to_advisor" => {
      template_type: "Liquid",
      path: File.join("advisements", "mailer", "email_to_advisor.text.liquid"),
      subject: I18n.t("notifications.advisement.email_to_advisor.subject"),
      to: "{{ record.professor.email }}",
      variables: {
        record: AdvisementDrop
      }
    },
    "class_enrollments:email_to_advisor" => {
      template_type: "Liquid",
      path: File.join(
        "class_enrollments", "mailer", "email_to_advisor.text.liquid"
      ),
      subject: I18n.t(
        "notifications.class_enrollment.email_to_advisor.subject"
      ),
      to: "{{ advisement.professor.email }}",
      variables: {
        record: ClassEnrollmentDrop,
        advisement: AdvisementDrop
      }
    },
    "class_enrollments:email_to_professor" => {
      template_type: "Liquid",
      path: File.join(
        "class_enrollments", "mailer", "email_to_professor.text.liquid"
      ),
      subject: I18n.t(
        "notifications.class_enrollment.email_to_professor.subject"
      ),
      to: "{{ record.course_class.professor.email }}",
      variables: {
        record: ClassEnrollmentDrop
      }
    },
    "class_enrollments:email_to_student" => {
      template_type: "Liquid",
      path: File.join(
        "class_enrollments", "mailer", "email_to_student.text.liquid"
      ),
      subject: I18n.t(
        "notifications.class_enrollment.email_to_student.subject"
      ),
      to: "{{ record.enrollment.student.email }}",
      variables: {
        record: ClassEnrollmentDrop
      }
    },
    "class_enrollment_requests:email_to_student" => {
      template_type: "Liquid",
      path: File.join(
        "class_enrollment_requests", "mailer", "email_to_student.text.liquid"
      ),
      subject: I18n.t(
        "notifications.class_enrollment_request.email_to_student.subject"
      ),
      to: "{{ record.class_enrollment.enrollment.student.email }}",
      variables: {
        record: ClassEnrollmentRequestDrop,
      }
    },
    "class_enrollment_requests:removal_email_to_student" => {
      template_type: "Liquid",
      path: File.join(
        "class_enrollment_requests", "mailer", "removal_email_to_student.text.liquid"
      ),
      subject: I18n.t(
        "notifications.class_enrollment_request.removal_email_to_student.subject"
      ),
      to: "{{ record.enrollment_request.enrollment.student.email }}",
      variables: {
        record: ClassEnrollmentRequestDrop,
      }
    },
    "course_classes:email_to_professor" => {
      template_type: "Liquid",
      path: File.join("course_classes", "mailer", "email_to_professor.text.liquid"),
      subject: I18n.t("notifications.course_class.email_to_professor.subject"),
      to: "{{ record.professor.email }}",
      variables: {
        record: CourseClassDrop
      }
    },
    "deferrals:email_to_advisor" => {
      template_type: "Liquid",
      path: File.join("deferrals", "mailer", "email_to_advisor.text.liquid"),
      subject: I18n.t("notifications.deferral.email_to_advisor.subject"),
      to: "{{ advisement.professor.email }}",
      variables: {
        record: DeferralDrop,
        advisement: AdvisementDrop
      }
    },
    "deferrals:email_to_student" => {
      template_type: "Liquid",
      path: File.join("deferrals", "mailer", "email_to_student.text.liquid"),
      subject: I18n.t("notifications.deferral.email_to_student.subject"),
      to: "{{ record.enrollment.student.email }}",
      variables: {
        record: DeferralDrop
      }
    },
    "devise:confirmation_instructions" => {
      template_type: "Liquid",
      path: File.join("devise", "mailer", "confirmation_instructions.text.liquid"),
      subject: I18n.t("devise.mailer.confirmation_instructions.subject"),
      to: "{{ user_email }}",
      variables: {
        user: UserDrop,
        confirmation_link: :value,
        user_email: :value
      }
    },
    "devise:email_changed" => {
      template_type: "Liquid",
      path: File.join("devise", "mailer", "email_changed.text.liquid"),
      subject: I18n.t("devise.mailer.email_changed.subject"),
      to: "{{ user.email }}",
      variables: {
        user: UserDrop,
        unconfirmed_email: :value
      }
    },
    "devise:invitation_instructions" => {
      template_type: "Liquid",
      path: File.join("devise", "mailer", "invitation_instructions.text.liquid"),
      subject: I18n.t("devise.mailer.invitation_instructions.subject"),
      to: "{{ user.email }}",
      variables: {
        user: UserDrop,
        accept_invitation_link: :value
      }
    },
    "devise:password_change" => {
      template_type: "Liquid",
      path: File.join("devise", "mailer", "password_change.text.liquid"),
      subject: I18n.t("devise.mailer.password_change.subject"),
      to: "{{ user.email }}",
      variables: {
        user: UserDrop,
      }
    },
    "devise:reset_password_instructions" => {
      template_type: "Liquid",
      path: File.join("devise", "mailer", "reset_password_instructions.text.liquid"),
      subject: I18n.t("devise.mailer.reset_password_instructions.subject"),
      to: "{{ user.email }}",
      variables: {
        user: UserDrop,
        edit_password_link: :value
      }
    },
    "devise:unlock_instructions" => {
      template_type: "Liquid",
      path: File.join("devise", "mailer", "unlock_instructions.text.liquid"),
      subject: I18n.t("devise.mailer.unlock_instructions.subject"),
      to: "{{ user.email }}",
      variables: {
        user: UserDrop,
        unlock_link: :value
      }
    },
    "enrollment_requests:email_to_student" => {
      template_type: "Liquid",
      path: File.join(
        "enrollment_requests", "mailer", "email_to_student.text.liquid"
      ),
      subject: I18n.t(
        "notifications.enrollment_request.email_to_student.subject"
      ),
      to: "{{ record.enrollment.student.email }}",
      variables: {
        record: EnrollmentRequestDrop,
        student_enrollment_url: :value,
        change: [ClassEnrollmentRequestDrop],
        keep: [ClassEnrollmentRequestDrop],
        message: :value,
        user: UserDrop
      }
    },
    "student_enrollments:email_to_student" => {
      template_type: "Liquid",
      path: File.join("student_enrollment", "mailer", "email_to_student.text.liquid"),
      subject: I18n.t("notifications.student_enrollment.email_to_student.subject"),
      to: "{{ record.enrollment.student.email }}",
      variables: {
        record: EnrollmentRequestDrop,
        new_insertion_requests: [ClassEnrollmentRequestDrop],
        remove_removal_requests: [ClassEnrollmentRequestDrop],
        existing_insertion_requests: [ClassEnrollmentRequestDrop],
        new_removal_requests: [ClassEnrollmentRequestDrop],
        remove_insertion_requests: [ClassEnrollmentRequestDrop],
        existing_removal_requests: [ClassEnrollmentRequestDrop],
        message: :value,
        user: UserDrop,
      }
    },
    "student_enrollments:email_to_advisor" => {
      template_type: "Liquid",
      path: File.join("student_enrollment", "mailer", "email_to_advisor.text.liquid"),
      subject: I18n.t("notifications.student_enrollment.email_to_advisor.subject"),
      to: "{{ advisement.professor.email }}",
      variables: {
        record: EnrollmentRequestDrop,
        advisement: AdvisementDrop,
        new_insertion_requests: [ClassEnrollmentRequestDrop],
        remove_removal_requests: [ClassEnrollmentRequestDrop],
        existing_insertion_requests: [ClassEnrollmentRequestDrop],
        new_removal_requests: [ClassEnrollmentRequestDrop],
        remove_insertion_requests: [ClassEnrollmentRequestDrop],
        existing_removal_requests: [ClassEnrollmentRequestDrop],
        message: :value,
        user: UserDrop,
      }
    },
    "student_enrollments:removal_email_to_student" => {
      template_type: "Liquid",
      path: File.join(
        "student_enrollment", "mailer", "removal_email_to_student.text.liquid"
      ),
      subject: I18n.t(
        "notifications.student_enrollment.removal_email_to_student.subject"
      ),
      to: "{{ record.enrollment.student.email }}",
      variables: {
        record: EnrollmentRequestDrop,
        requesting: :value
      }
    },
    "student_enrollments:removal_email_to_advisor" => {
      template_type: "Liquid",
      path: File.join(
        "student_enrollment", "mailer", "removal_email_to_advisor.text.liquid"
      ),
      subject: I18n.t(
        "notifications.student_enrollment.removal_email_to_advisor.subject"
      ),
      to: "{{ advisement.professor.email }}",
      variables: {
        record: EnrollmentRequestDrop,
        advisement: AdvisementDrop,
        requesting: :value
      }
    },
  }

  def self.devise_template(action)
    name = "devise:#{action}"
    self.load_template(name)
  end

  def self.load_template(name)
    template = EmailTemplate.find_by_name(name)
    if template.blank?
      template = EmailTemplate.new
      template.name = name
      builtin = BUILTIN_TEMPLATES[name]
      unless builtin.blank?
        template.template_type = builtin[:template_type]
        template.subject = builtin[:subject]
        template.to = builtin[:to]
        template.body = File.read File.join(
          Rails.root, "app", "views", builtin[:path]
        )
      end
    end
    template
  end

  def update_mailer_headers(headers)
    unless CustomVariable.redirect_email.nil?
      headers[:subject] = headers[:subject] +
        " (Originalmente para #{headers[:to]})"
      headers[:to] = CustomVariable.redirect_email
      headers[:skip_redirect] = true
    end
    headers[:reply_to] = CustomVariable.reply_to
    headers[:skip_message] = ! self.enabled
    headers[:skip_footer] = true
  end

  def load_drop(variables, key, value)
    if variables.key?(key)
      cls = variables[key]
      if cls == :value
        result = value
      elsif cls.kind_of?(Array)
        result = value.map { |v| cls[0].new(v) }
      else
        result = cls.new(value)
      end
    else
      result = value
    end
    result
  end

  def prepare_message(bindings)
    if self.template_type == "Liquid"
      builtin = BUILTIN_TEMPLATES[self.name] || {}
      variables = builtin[:variables] || {}
      bindings = bindings.map { |k, v| [k.to_s, load_drop(variables, k, v)] }.to_h
      bindings["variables"] = VariablesDrop.new
    end
    formatter = FormatterFactory.create_formatter(bindings, self.template_type)
    message = {
      to: formatter.format(self.to),
      subject: formatter.format(self.subject),
      body: formatter.format(self.body),
      skip_footer: true
    }
    self.update_mailer_headers(message)
    message
  end

  def self.disable_erb_validation!
    @@disable_erb_validation = true
    yield
    @@disable_erb_validation = false
  end

  private
    def cannot_create_new_erb_template
      return if @@disable_erb_validation
      email_template = self.paper_trail.previous_version
      current_to = I18n.transliterate(self.to).downcase
      current_subject = I18n.transliterate(self.subject).downcase
      current_body = I18n.transliterate(self.body).downcase
      while email_template.present?
        old_to = I18n.transliterate(email_template.to).downcase
        old_subject = I18n.transliterate(email_template.subject).downcase
        old_body = I18n.transliterate(email_template.body).downcase
        all_same_ERB = (
          current_to == old_to &&
          current_subject == old_subject &&
          current_body == old_body &&
          email_template.template_type == ERB
        )
        if all_same_ERB
          return
        end
        email_template = email_template.paper_trail.previous_version
      end
      errors.add(:body, :cannot_create_new_erb_template)
    end
end

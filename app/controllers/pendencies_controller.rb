# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PendenciesController < ApplicationController
  authorize_resource class: false

  def index
    raise CanCan::AccessDenied.new if cannot? :read, :pendency
    raise CanCan::AccessDenied.new if current_user.nil?
    @partials = []

    pendency_condition = EnrollmentRequest.pendency_condition
    requests = EnrollmentRequest.where(pendency_condition)
    unless requests.empty?
      @partials << [
        "pendencies/enrollment_requests",
        { conditions: pendency_condition }
      ]
    end

    class_pendency_condition = ClassEnrollmentRequest.pendency_condition
    class_requests = ClassEnrollmentRequest.where(class_pendency_condition)
    unless class_requests.empty?
      @partials << [
        "pendencies/class_enrollment_requests",
        { conditions: class_pendency_condition }
      ]
    end

    admission_application_condition = Admissions::AdmissionApplication.pendency_condition
    candidates = Admissions::AdmissionApplication.where(admission_application_condition)
    unless candidates.empty?
      @partials << [
        "pendencies/admission_applications",
        { conditions: admission_application_condition }
      ]
    end

    course_class_condition = CourseClass.pendency_condition
    course_classes = CourseClass.where(course_class_condition)
    unless course_classes.empty?
      @partials << [
        "pendencies/course_classes",
        { conditions: course_class_condition }
      ]
    end

    render :index
  end
end

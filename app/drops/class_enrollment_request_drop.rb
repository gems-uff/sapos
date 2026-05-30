# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ClassEnrollmentRequestDrop < ActiveRecordAttributesDrop
  define_drop_relationship :enrollment_request, EnrollmentRequestDrop
  define_drop_relationship :course_class, CourseClassDrop
  define_drop_relationship :class_enrollment, ClassEnrollmentDrop
end

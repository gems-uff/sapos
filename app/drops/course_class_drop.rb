# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseClassDrop < ActiveRecordAttributesDrop
  define_drop_relationship :professor, ProfessorDrop
  define_drop_relationship_many :class_enrollments, ClassEnrollmentDrop
  define_drop_accessor :label_with_course
  define_drop_accessor :label_for_email_subject
  define_drop_accessor :name_with_class
  define_drop_accessor :to_label
end

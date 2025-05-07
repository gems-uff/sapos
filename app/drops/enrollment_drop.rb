# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class EnrollmentDrop < ActiveRecordAttributesDrop
  define_drop_relationship :student, StudentDrop
  define_drop_accessor :to_label
end

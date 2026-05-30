# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AdvisementDrop < ActiveRecordAttributesDrop
  define_drop_relationship :professor, ProfessorDrop
  define_drop_relationship :enrollment, EnrollmentDrop

end

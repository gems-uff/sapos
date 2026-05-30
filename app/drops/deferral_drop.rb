# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DeferralDrop < ActiveRecordAttributesDrop
  define_drop_relationship :enrollment, EnrollmentDrop
  define_drop_relationship :deferral_type, DeferralTypeDrop

end

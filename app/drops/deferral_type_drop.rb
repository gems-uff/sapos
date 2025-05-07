# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DeferralTypeDrop < ActiveRecordAttributesDrop
  define_drop_relationship :phase, PhaseDrop
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module DeferralTypesHelper
  def options_for_association_conditions(association, record)
    if association.name == :phase
      Phase.find_all_for_enrollment(nil)
    else
      super
    end
  end
end

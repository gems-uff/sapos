# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ResearchAreasHelper
  def permit_rs_browse_params
    [:page, :update, :utf8]
  end
end

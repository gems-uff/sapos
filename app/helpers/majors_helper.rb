# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module MajorsHelper
  def permit_rs_browse_params
    [:page, :update, :utf8]
  end
end

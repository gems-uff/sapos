# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Fix running tests in the first day of the month

module DateHelpers
  def middle_of_month(date)
    Date.new(date.year, date.month, 15)
  end
end

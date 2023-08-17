# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DateUtils
  def self.add_to_date(date, total_semesters, total_months, total_days)
    if total_semesters != 0
      semester_months = (
        12 * (total_semesters / 2)
      ) + (
        (date.month == 3 ? 5 : 7) * (total_semesters % 2)
      ) - 1
      date = semester_months.months.since(date).end_of_month
    end

    total_days.days.since(total_months.months.since(date).end_of_month)
  end

  def self.add_hash_to_date(date, hash)
    DateUtils.add_to_date(date, hash[:semesters], hash[:months], hash[:days])
  end
end

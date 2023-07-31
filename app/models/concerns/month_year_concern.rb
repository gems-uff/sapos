# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Model Concern that allows the assignment of month-year dates in Rails 6.1
module MonthYearConcern
  extend ActiveSupport::Concern

  class_methods do
    def month_year_date(attribute)
      @month_years << attribute
    end

    def defined_month_years
      @month_years
    end
  end

  included do
    @month_years = []

    def assign_multiparameter_attributes(pairs)
      self.class.defined_month_years.each do |attribute|
        found_day = nil
        found_month = nil
        found_year = nil
        pairs.each do |name, value|
          found_day = value if name == "#{attribute}(3i)"
          found_month = value if name == "#{attribute}(2i)"
          found_year = value if name == "#{attribute}(1i)"
        end
        if found_day == "1" && found_month == "" && found_year == ""
          pairs.delete(["#{attribute}(3i)", "1"])
          pairs << ["#{attribute}(3i)", ""]
          found_day = ""
        end
        next if found_day.present? || found_month.blank? || found_year.blank?

        pairs.delete(["#{attribute}(3i)", ""]) if found_day == ""
        pairs << ["#{attribute}(3i)", "1"]
      end
      super(pairs)
    end
  end
end

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# In Rails 7.0, Date.to_se stopped considering the :default format
# and deprecated it
# This monkeypatch restores the functionality
# Extracted from https://stackoverflow.com/questions/71177165/rails-ignores-the-default-date-format-after-upgrading-from-6-1-to-7-0

require "date"

class Date
  def to_s(format = :default)
    if formatter = DATE_FORMATS[format]
      if formatter.respond_to?(:call)
        formatter.call(self).to_s
      else
        strftime(formatter)
      end
    else
      to_default_s
    end
  end
end

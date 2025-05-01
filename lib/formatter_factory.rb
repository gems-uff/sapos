# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module FormatterFactory
  def self.create_formatter(bindings, template_type)
    if template_type == "ERB"
      cls = ErbFormatter
    else
      cls = LiquidFormatter
    end
    cls.new(bindings)
  end
end

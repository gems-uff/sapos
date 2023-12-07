# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module CodeEvaluator
  def self.evaluate_code(formula, **bindings)
    b = binding
    bindings.each do |var, val| b.local_variable_set(var, val) end

    b.eval(formula)
  end
end

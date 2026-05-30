# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class VariablesDrop < Liquid::Drop
  @@variables = []
  CustomVariable::VARIABLES.each do |varname, typ|
    @@variables.push(varname)
    define_method varname.to_sym do
      CustomVariable.public_send(varname.to_sym)
    end
  end

  def to_s
    "variables(#{@@variables.join(', ')})"
  end
end
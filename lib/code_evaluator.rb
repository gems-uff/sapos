# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true
 
module CodeEvaluator
  def self.create_formatter(bindings, template_type, drops = nil)
    if template_type == "ERB"
      cls = ErbFormatter
    else
      cls = LiquidFormatter
      bindings = CodeEvaluator.dropify_bindings(bindings, drops)
    end
    cls.new(bindings)
  end

  def self.evaluate_code(code, bindings, template_type, drops = nil)
    if template_type == "Ruby"
      b = binding
      bindings.each do |var, val|
        b.local_variable_set(var, val)
      end
      b.eval(code)
    elsif template_type == "ERB"
      ErbFormatter.new(bindings).format(code)
    else
      bindings = CodeEvaluator.dropify_bindings(bindings, drops)
      LiquidFormatter.new(bindings).format(code)
    end
  end

  private
    def self.dropify_bindings(bindings, drops)
      drops ||= {}
      new_bindings = bindings.map { |k, v| CodeEvaluator.load_drop(drops, k, v) }.to_h
      new_bindings["variables"] = VariablesDrop.new unless new_bindings.key?("variables")
      new_bindings
    end

    def self.load_drop(drops, key, value)
      return [key, value] unless drops.key?(key)  # Does not convert if key is not in drops map
      cls = drops[key]
      return [key.to_s, value] if cls == :value
      return [key.to_s, value.map { |v| cls[0].new(v) }] if cls.kind_of?(Array)
      [key.to_s, cls.new(value)]
    end
end

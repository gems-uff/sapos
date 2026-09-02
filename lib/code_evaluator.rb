# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module CodeEvaluator
  # Escapes that turn the data of a template into text, one per destination.
  #
  # A template mixes markup written by its author with data that comes from a
  # query, and only the author writes markup: a thesis titled "O uso de
  # <strong>" is a title, not a request for bold text. The data is escaped
  # when the template is rendered, so the two are told apart by where they
  # come from instead of by what they look like.
  #
  # The destinations do not read the same entities back. Prawn only knows
  # &lt;, &gt; and &amp;, and prints anything else as it is written, so a name
  # such as "Sant'Anna" has to keep its apostrophe. HTML escapes the quotes as
  # well, because a template may write data inside an attribute.
  ESCAPES = {
    html: ->(text) { ERB::Util.html_escape(text).to_s },
    pdf: ->(text) do
      text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end
  }.freeze

  def self.escaper(destination)
    return nil if destination.blank?
    ESCAPES.fetch(destination)
  end

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
      new_bindings = bindings.to_h { |k, v| CodeEvaluator.load_drop(drops, k, v) }
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

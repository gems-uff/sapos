# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true


module SaposLiquidFilters
  def localize(date, format = :default)
    time = ((date.class == String) ? Time.parse(date) : date.to_time)
    I18n.localize(time, format: format.to_sym)
  end

  def avg(input, property = nil)
    values_for_sum = self.to_number(input, property)
    result = Liquid::StandardFilters::InputIterator.new(values_for_sum, context).sum do |item|
      Liquid::Utils.to_number(item)
    end
    result.to_f / values_for_sum.size
  end

  def median(input, property = nil)
    values = self.to_number(input, property)
    sorted = values.sort
    length = values.size
    (sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0
  end

  alias_method :l, :localize

  private
    def to_number(input, property = nil)
      ary = Liquid::StandardFilters::InputIterator.new(input, context)
      return 0 if ary.empty?

      ary.map do |item|
        if property.nil?
          Liquid::Utils.to_number(item)
        elsif item.respond_to?(:[])
          Liquid::Utils.to_number(item[property])
        else
          0
        end
      rescue TypeError
        raise Liquid::ArgumentError, "cannot select the property '#{Liquid::Utils.to_s(property)}'"
      end
    end
end

class RoleEmail < Liquid::Tag
  def initialize(tag_name, role_name, tokens)
    super
    @role_name = role_name.strip
  end

  def render(context)
    Role.find_by(name: @role_name).users.map(&:email).join(";")
  end
end

class LanguageTag < Liquid::Block
  @lang = nil
  def initialize(tag_name, markup, tokens)
    super

    @lang = markup.strip.to_sym
  end

  def render(context)
    old = I18n.locale
    begin
      I18n.locale = @lang
      super
    ensure
      I18n.locale = old
    end
  end
end

class AlignBlock < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    @align = (markup.strip.presence || "justify").to_sym
  end

  def render(context)
    content = super
    "<div style=\"text-align: #{@align};\">#{content}</div>"
  end
end

class LiquidFormatter
  # Applies an escape of CodeEvaluator::ESCAPES to the output of every {{ }},
  # so that the markup of the template is left untouched and only the data
  # that fills it becomes text.
  #
  # Liquid hands an array to the filter before joining it, so the items are
  # escaped one by one to keep the output that liquid produces without it.
  def self.escape_filter(escaper)
    ->(output) do
      case output
      when nil then output
      when Array then output.map { |item| escaper.call(item.to_s) }
      else escaper.call(output.to_s)
      end
    end
  end

  @attributes = {}

  def initialize(hash)
    @attributes = hash
    self.set_records!
  end

  def set_records!
    if !@attributes.key?("records") && @attributes.key?(:columns) && @attributes.key?(:rows)
      @attributes["records"] = []
      keys = @attributes[:columns]
      @attributes[:rows].each do |row|
        @attributes["records"] << Hash[keys.zip(row)]
      end
    end
  end

  # Renders a template, escaping the data when it is read as markup.
  #
  # The body of an assertion is printed as markup by prawn (:pdf) and the body
  # of a notification is delivered as html (:html). A recipient and a subject
  # are headers, not markup, and are rendered without any escape.
  def format(code, escape_data: nil)
    env = Liquid::Environment.new
    env.register_filter(SaposLiquidFilters)
    env.register_tag("emails", RoleEmail)
    env.register_tag("language", LanguageTag)
    env.register_tag("align", AlignBlock)
    @template = Liquid::Template.parse(code, environment: env)
    context = Liquid::Context.build(environment: env, environments: @attributes)
    escaper = CodeEvaluator.escaper(escape_data)
    context.global_filter = LiquidFormatter.escape_filter(escaper) if escaper
    @template.render(context)
  end
end

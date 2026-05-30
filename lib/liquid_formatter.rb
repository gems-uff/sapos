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
    Role.find_by(name: @role_name).users.map(&:email).join(';')
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
      return super
    ensure
      I18n.locale = old
    end
  end
end


class LiquidFormatter
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

  def format(code)
    env = Liquid::Environment.new
    env.register_filter(SaposLiquidFilters)
    env.register_tag('emails', RoleEmail)
    env.register_tag('language', LanguageTag)
    @template = Liquid::Template.parse(code, environment: env)
    @template.render(@attributes)    
  end
end

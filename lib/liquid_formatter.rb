# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true


module SaposLiquidFilters
  def localize(date, format = :default)
    time = ((date.class == String) ? Time.parse(date) : date.to_time)
    I18n.localize(time, format: format.to_sym)
  end

  alias_method :l, :localize
end
Liquid::Template.register_filter(SaposLiquidFilters)

class RoleEmail < Liquid::Tag
  def initialize(tag_name, role_name, tokens)
     super
     @role_name = role_name.strip
  end

  def render(context)
    Role.find_by(name: @role_name).users.map(&:email).join(';')
  end
end
Liquid::Template.register_tag('emails', RoleEmail)

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

Liquid::Template.register_tag('language', LanguageTag)


class LiquidFormatter
  @attributes = {}

  def initialize(hash)
    @attributes = hash
    self.set_records!
  end

  def set_records!
    unless @attributes["records"]
      @attributes["records"] = []
      keys = @attributes[:columns]
      @attributes[:rows].each do |row|
        @attributes["records"] << Hash[keys.zip(row)]
      end
    end
  end

  def format(code)
    
    @template = Liquid::Template.parse(code)
    @template.render(@attributes)    
  end
end

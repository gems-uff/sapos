# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "erubi"

class ErbFormatter
  @attributes = {}
  @records = nil

  def initialize(hash)
    @attributes = hash
  end


  def var(val)
    escape_data(@attributes[val])
  end

  def records
    unless @records
      @records = []
      keys = @attributes[:columns]
      @attributes[:rows].each do |row|
        @records << Hash[keys.zip(escape_data(row))]
      end
    end
    @records
  end

  def localize(date, format = :default)
    time = ((date.class == String) ? Time.parse(date) : date.to_time)
    I18n.localize(time, format: format)
  end

  alias_method :l, :localize

  # Renders a template, escaping the data when it is read as markup.
  #
  # See LiquidFormatter#format: erb templates cannot be created anymore, but
  # the ones that already exist read the same data and are printed and
  # delivered through the same path, so they escape it as well. The names of
  # the columns are keys, not data, and are kept as they are.
  def format(code, escape_data: nil)
    @escaper = CodeEvaluator.escaper(escape_data)
    @records = nil
    eval(Erubi::Engine.new(code).src)
  end

  private
    def escape_data(value)
      return value if @escaper.nil?
      case value
      when String then @escaper.call(value)
      when Array then value.map { |item| escape_data(item) }
      when Hash then value.transform_values { |item| escape_data(item) }
      else value
      end
    end
end

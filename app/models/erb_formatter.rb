# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ERBFormatter

  @attributes = {}
  @records = nil

  def initialize(hash)
    @attributes = hash
  end


  def var(val)
    @attributes[val]
  end

  def records
    unless @records
      @records = []
      keys = var(:columns)
      var(:rows).each do |row|
        @records << Hash[keys.zip(row)]
      end
    end
    @records
  end

  def localize(date, format = :default)
    time = ((date.class == String) ? Time.parse(date) : date.to_time)
    I18n.localize(time, :format => format)
  end

  alias_method :l, :localize

  def format(code)
    ERB.new(code, 0).result(binding)
  end
end

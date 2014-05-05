# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class QueryParam < ActiveRecord::Base
  belongs_to :query
  attr_accessible :name, :default_value, :value_type

  attr_accessor :simulation_value

  VALUE_STRING = 'String'
  VALUE_INTEGER = 'Integer'
  VALUE_FLOAT = 'Float'
  VALUE_LIST = 'List'
  VALUE_DATE = 'Date'
  VALUE_DATETIME = 'DateTime'
  VALUE_TIME = 'Time'
  VALUE_LITERAL = 'Literal'

  VALUE_TYPES = [VALUE_STRING, VALUE_INTEGER, VALUE_FLOAT, VALUE_LIST, VALUE_LITERAL, VALUE_DATE, VALUE_DATETIME, VALUE_TIME, VALUE_LITERAL]

  validates :value_type, presence: true, inclusion: VALUE_TYPES
  validates :name, presence: true, :format => /^([a-z_][a-zA-Z_0-9]+)?$/


  def type
    @type ||= ActiveSupport::StringInquirer.new(self.value_type.downcase)
  end

  def value
    self.simulation_value || self.default_value
  end

  def parsed_value
    case value_type
      when VALUE_DATE
        Date.parse(value)
      when VALUE_DATETIME
        DateTime.parse(value)
      when VALUE_TIME
        Time.parse(value)
      when VALUE_LIST
        value.split(',')
      when VALUE_INTEGER
        value.to_i
      when VALUE_FLOAT
        value.to_f
      when VALUE_LITERAL
        value
      else
        value
    end
  end
end
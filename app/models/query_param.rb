# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class QueryParam < ActiveRecord::Base
  belongs_to :query
  has_many :notification_params

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
  validates :name, presence: true, :format => /\A([a-z_][a-zA-Z_0-9]+)?\z/

  validate do
    validate_value(default_value)
  end

  def simulation_value=(val)
    @simulation_value = val
  end


  def validate_value(val)
    unless val.to_s.empty?
      case value_type
        when VALUE_DATE
          begin
            unless val.is_a?(ActiveSupport::TimeWithZone)
              Date.parse(val)
              unless val =~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/
                raise ArgumentError
              end
            end
          rescue ArgumentError
            self.errors.add :default_value, :invalid_date
          end
          val
        when VALUE_DATETIME
          begin
            DateTime.parse(val)
            unless val =~ /[0-9]{4}-[0-9]{2}-[0-9]{2} [09]{2}:[09]{2}:[09]{2}/
              raise ArgumentError
            end
          rescue ArgumentError
            self.errors.add :default_value, :invalid_date_time
          end
          val
        when VALUE_TIME
          begin
            Time.parse(val)
            unless val =~ /[09]{2}:[09]{2}:[09]{2}/
              raise ArgumentError
            end
          rescue ArgumentError
            self.errors.add :default_value, :invalid_time
          end

        when VALUE_INTEGER
          if val.to_i.to_s != val.to_s
            self.errors.add :default_value, :invalid_integer
          end
        when VALUE_FLOAT
          if val.to_f.to_s != val.to_s
            self.errors.add :default_value, :invalid_float
          end
      end
    end
  end


  def type
    @type ||= ActiveSupport::StringInquirer.new(self.value_type.downcase)
  end

  def value
    self.simulation_value || self.default_value
  end

  def parsed_value
    if value.to_s.empty?
      value
    else
      case value_type
        when VALUE_DATE
          if value.is_a?(ActiveSupport::TimeWithZone)
            value.to_date
          else
            Date.parse(value)
          end
        when VALUE_DATETIME
          if value.is_a?(ActiveSupport::TimeWithZone)
            value.to_datetime
          else
            DateTime.parse(value)
          end
        when VALUE_TIME
          Time.parse(value)
        when VALUE_LIST
          list_value = value.split(',')
          if list_value.find { |i| i =~ /[^0-9.]/ }
            list_value
          else
            if list_value.find { |i| i =~ /[^0-9]/ }
              list_value.collect &:to_i
            else
              list_value.collect &:to_f
            end
          end
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
end
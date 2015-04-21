# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class NotificationParam < ActiveRecord::Base
  belongs_to :notification, :inverse_of => :params, :touch => true
  belongs_to :query_param


  delegate :name, :value_type, :type, :default_value, to: :query_param

  validate do
    if self.query_param.query.id != self.notification.query.id
      self.errors.add :value, :mismatch_query
    end


    # Copied from QueryParam, extract to module or concern
    unless value.to_s.empty?
      case value_type
        when QueryParam::VALUE_DATE
          begin
            unless value.is_a?(ActiveSupport::TimeWithZone)
              Date.parse(value)
            end
          rescue ArgumentError
            self.errors.add :default_value, :invalid_date
          end
          value
        when QueryParam::VALUE_DATETIME
          begin
            DateTime.parse(value)
          rescue ArgumentError
            self.errors.add :default_value, :invalid_date_time
          end
          value
        when QueryParam::VALUE_TIME
          begin
            Time.parse(value)
          rescue ArgumentError
            self.errors.add :default_value, :invalid_time
          end

        when QueryParam::VALUE_INTEGER
          if value.to_i.to_s != value.to_s
            self.errors.add :default_value, :invalid_integer
          end
        when QueryParam::VALUE_FLOAT
          if value.to_f.to_s != value.to_s
            self.errors.add :default_value, :invalid_float
          end
      end
    end
  end


  def parsed_value
    self.query_param.parsed_value
  end
end

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Query < ActiveRecord::Base

  has_many :notifications, inverse_of: :query
  has_many :params, class_name: 'QueryParam'

  attr_accessible :name, :sql

  accepts_nested_attributes_for :params, reject_if: :all_blank

  validate :ensure_valid_params

  def map_params
    current_params = {}
    self.params.each do |param|
      case param.value_type
        when 'Date'
          current_params[param.name.to_sym] = Date.parse(param.default_value)
        when 'DateTime'
          current_params[param.name.to_sym] = DateTime.parse(param.default_value)
        when 'List'
          current_params[param.name.to_sym] = param.default_value.split(',')
        when 'Number'
          current_params[param.name.to_sym] = param.default_value.to_f
        when 'Literal'
          current_params[param.name.to_sym] = param.default_value
        else
          current_params[param.name.to_sym] = param.default_value
      end
    end
    current_params
  end

  def self.parse_sql_and_params(sql, params)
    self.send(:sanitize_sql, [sql, params])
  end

  def execute(options={})
    #Create connection to the Database
    db_connection = ActiveRecord::Base.connection

    #Generate query using the parameters specified by the notification
    current_params = map_params

    generated_query = ::Query.parse_sql_and_params(sql, current_params)

    #Query the Database
    db_resource = db_connection.exec_query(generated_query)

    #Build the notifications with the results from the query
    {:columns => db_resource.columns, :rows => db_resource.rows, :query => generated_query}
  end


  def ensure_valid_params
    begin
      self.execute
    rescue ActiveRecord::PreparedStatementInvalid => e
      variable_name = e.message.match(/missing value for :([a-zA-Z0-9_]+)/)[1]

      self.errors.add(:base, "O parametro #{variable_name} foi usado na query mas nao foi definido.")
    end
  end
end

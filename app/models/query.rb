# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Query < ActiveRecord::Base

  has_many :notifications, inverse_of: :query
  has_many :params, class_name: 'QueryParam'

  attr_accessible :name, :sql

  accepts_nested_attributes_for :params, reject_if: :all_blank

  validate :ensure_valid_params

  def map_params(simulation_params = {})
    current_params = {}
    self.params.each do |param|
      param_name = param.name.to_sym
      param.simulation_value = simulation_params[param_name]
      current_params[param_name] = param.parsed_value
    end
    current_params
  end

  def self.parse_sql_and_params(sql, params)
    self.send(:sanitize_sql, [sql, params])
  end


  def execute(options={:simulation_params => {} })
    #Create connection to the Database
    db_connection = ActiveRecord::Base.connection

    #Generate query using the parameters specified by the notification
    current_params = map_params(options[:simulation_params].symbolize_keys)

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

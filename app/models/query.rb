# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Query
class Query < ApplicationRecord
  has_many :notifications, inverse_of: :query
  has_many :params,
    class_name: "QueryParam",
    dependent: :destroy, validate: false,
    before_add: :get_query_param_ids,
    before_remove: :get_query_param_ids

  accepts_nested_attributes_for :params,
    reject_if: :all_blank,
    allow_destroy: true

  validates :name, presence: true
  validates :sql, presence: true
  validate :ensure_valid_params
  validates_associated :params

  after_update :after_update_query

  def after_update_query
    return if @query_param_ids_before_query_update.nil?
    return if self.params.ids.to_set == @query_param_ids_before_query_update
    self.notifications.each do |notification|
      notification.touch
    end
  end

  def get_query_param_ids(param)
    @query_param_ids_before_query_update = self.params.ids.to_set
  end

  def map_params(simulation_params = {})
    simulation_params = simulation_params.symbolize_keys
    current_params = {}
    self.params.each do |param|
      param_name = param.name.to_sym
      param.simulation_value = simulation_params[param_name]
      param.validate_value(param.simulation_value)

      current_params[param_name] =
        param.errors.empty? ? param.parsed_value : ""
    end
    current_params
  end

  def self.parse_sql_and_params(sql, params)
    self.send(:sanitize_sql, [sql, params])
  end


  def run_read_only_query(query)
    if ApplicationRecord.connection.adapter_name == "SQLite"
      db_resource = ApplicationRecord.connection.exec_query(query)

      { columns: db_resource.columns, rows: db_resource.rows }
    elsif ApplicationRecord.connection.adapter_name == "Mysql2"
      conf = ApplicationRecord.configurations
      client = Mysql2::Client.new(
        conf.configs_for(env_name: "#{Rails.env}_read_only")[0] ||
        conf.configs_for(env_name: conf[Rails.env])[0]
      )
      results = client.query(query)
      client.close

      { columns: results.fields, rows: results.entries.collect(&:values) }
    end
  end

  def execute(override_params = {})
    # Generate query using the parameters specified by the simulation
    current_params = map_params(override_params)

    valid_params = self.params.find { |p| p.errors.size.nonzero? }.nil?

    if !valid_params
      { columns: [], rows: [], query: "", errors: self.params }
    else

      generated_query = ::Query.parse_sql_and_params(sql, current_params)

      # Query the Database safely
      db_resource = run_read_only_query(generated_query)

      # Build the notifications with the results from the query
      db_resource.merge(query: generated_query, errors: self.errors)
    end
  end


  def ensure_valid_params
    return if sql.nil? || sql.strip.empty?
    begin
      self.execute
    rescue ActiveRecord::PreparedStatementInvalid => e
      variable_name = e.message.match(/missing value for :([a-zA-Z0-9_]+)/)[1]
      self.errors.add(
        :sql, :sql_has_an_undefined_parameter, parametro: variable_name
      )
    rescue Exception => e
      self.errors.add(:sql, :sql_execution_generated_an_error, erro: e.message)
    end
  end
end

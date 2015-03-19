# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Query < ActiveRecord::Base

  has_many :notifications, inverse_of: :query
  has_many :params, class_name: 'QueryParam'


  accepts_nested_attributes_for :params, reject_if: :all_blank, allow_destroy: true

  validate :ensure_valid_params
  validates_associated :params

  def map_params(simulation_params = {})
    simulation_params = simulation_params.symbolize_keys
    current_params = {}
    self.params.each do |param|
      param_name = param.name.to_sym
      param.simulation_value = simulation_params[param_name]
      param.validate_value(param.simulation_value)

      current_params[param_name] = (param.errors.empty? ? param.parsed_value : '')
    end
    current_params
  end

  def self.parse_sql_and_params(sql, params)
    self.send(:sanitize_sql, [sql, params])
  end


  def within_read_only_connection(&block)
    if ActiveRecord::Base.connection.adapter_name == "SQLite"
      return yield block
    end
    begin
      ActiveRecord::Base.establish_connection("#{Rails.env}_read_only") if ActiveRecord::Base.configurations["#{Rails.env}_read_only"]
      yield block
    ensure
      ActiveRecord::Base.establish_connection(Rails.env)
    end
  end

  def execute(override_params = {})
    #Generate query using the parameters specified by the simulation
    current_params = map_params(override_params)

    valid_params = self.params.find { |p| p.errors.size.nonzero? }.nil?

    if not valid_params
      {:columns => [], :rows => [], :query => '', :errors => self.params}
    else

      generated_query = ::Query.parse_sql_and_params(sql, current_params)
      ActiveRecord::Base.connection.commit_db_transaction

      columns = []
      rows = []

      # TODO: Connections and transactions are messed up, need to upgrade to Rails 4 to use connection pool.
      within_read_only_connection do
        #Create connection to the Database
        db_connection = ActiveRecord::Base.connection
        #Query the Database
        db_resource = db_connection.exec_query(generated_query)

        columns = db_resource.columns
        rows = db_resource.rows
      end
      #Build the notifications with the results from the query
      {:columns => columns, :rows => rows, :query => generated_query, :errors => self.errors}
    end
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

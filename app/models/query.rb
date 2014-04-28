class Query < ActiveRecord::Base

  has_many :notifications, inverse_of: :query
  has_many :params, class_name: 'QueryParam'

  attr_accessible :name, :sql

  accepts_nested_attributes_for :params, reject_if: :all_blank


  def try_field(field, &block)
    begin
      return yield
    rescue Exception => e
      raise [field, e.to_s].join(' -:- ')
    end
  end

  def map_params
    current_params = {}
    self.params.each do |param|
      current_params[param.name.to_sym] = param.default_value
    end
    current_params
  end

  def execute(options={})
    #Create connection to the Database
    db_connection = ActiveRecord::Base.connection

    #Generate query using the parameters specified by the notification
    current_params = map_params

    #Query the Database
    db_resource = db_connection.exec_query(sql, current_params)

    #Build the notifications with the results from the query
    {:columns => db_resource.columns, :rows => db_resource.rows}
  end
end

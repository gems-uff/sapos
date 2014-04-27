class Query < ActiveRecord::Base

  has_many :notifications, inverse_of: :query

  attr_accessible :name, :sql
end

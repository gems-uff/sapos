class Query < ActiveRecord::Base

  has_many :notifications, inverse_of: :query
  has_many :params, class_name: 'QueryParam'

  attr_accessible :name, :sql

  accepts_nested_attributes_for :params, reject_if: :all_blank


  def execute
    []
  end
end

class Report < ActiveRecord::Base
  belongs_to :query

  validates :name, presence: true, length: {within: 1..100}
  validates :description, presence: true, length: {within: 1..255}
  validates :query_id, presence: true
  validates :has_table, inclusion: [true, false]
  validates :table_name, presence: true, length: { within: 1..50 }, if: :has_table?

  validates_associated :query
end

class AddQueryIdToAssertions < ActiveRecord::Migration[7.0]
  def change
    add_reference :assertions, :query, null: true, foreign_key: true
  end
end
class ChangeQueryIdInAssertions < ActiveRecord::Migration[7.0]
  def change
    change_column_null :assertions, :query_id, false
  end
end

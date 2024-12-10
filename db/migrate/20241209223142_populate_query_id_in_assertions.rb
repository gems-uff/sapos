class PopulateQueryIdInAssertions < ActiveRecord::Migration[7.0]
  def up
    default_query = Query.first
    Assertion.update_all(query_id: default_query.id) if default_query
  end

  def down
    # No need to revert data changes
  end
end
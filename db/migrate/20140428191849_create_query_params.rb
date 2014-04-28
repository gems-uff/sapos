class CreateQueryParams < ActiveRecord::Migration
  def change
    create_table :query_params do |t|
      t.references :query
      t.string :name
      t.string :default_value
      t.string :value_type

      t.timestamps
    end
    add_index :query_params, :query_id
  end
end

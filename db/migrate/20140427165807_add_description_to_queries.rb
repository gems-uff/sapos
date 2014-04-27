class AddDescriptionToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :description, :string, after: :sql
  end
end

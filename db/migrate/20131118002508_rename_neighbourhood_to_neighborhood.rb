class RenameNeighbourhoodToNeighborhood < ActiveRecord::Migration
  def change
  	rename_column :professors, :neighbourhood, :neighborhood
  	rename_column :students, :neighbourhood, :neighborhood
  end
end

class AddAvailableToResearchArea < ActiveRecord::Migration[7.0]
  def up
    add_column :research_areas, :available, :boolean, default: true
  end

  def down
    remove_column :research_areas, :available
  end
end

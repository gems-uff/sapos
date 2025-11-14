class AddAvailableToResearchLine < ActiveRecord::Migration[7.0]
  def up
    add_column :research_lines, :available, :boolean, default: true
  end

  def down
    remove_column :research_lines, :available
  end
end

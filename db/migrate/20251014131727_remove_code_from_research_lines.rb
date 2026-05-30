class RemoveCodeFromResearchLines < ActiveRecord::Migration[7.0]
  def up
    remove_column :research_lines, :code
  end
  def down
    add_column :research_lines, :code, :string
  end
end

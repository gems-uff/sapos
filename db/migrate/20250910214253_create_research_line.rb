class CreateResearchLine < ActiveRecord::Migration[7.0]
  def up
    create_table :research_lines do |t|
      t.string :name
      t.string :code
      t.references :research_area, null: false, foreign_key: true

      t.timestamps
    end
  end

  def down
    drop_table :research_lines
  end
end

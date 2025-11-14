class CreateCourseResearchLine < ActiveRecord::Migration[7.0]
  def up
    create_table :course_research_lines do |t|
      t.references :course, null: false, foreign_key: true
      t.references :research_line, null: false, foreign_key: true

      t.timestamps
    end
  end

  def down
    drop_table :course_research_lines
  end
end

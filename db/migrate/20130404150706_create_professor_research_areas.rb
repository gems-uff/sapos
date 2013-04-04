class CreateProfessorResearchAreas < ActiveRecord::Migration
  def self.up
    create_table :professor_research_areas do |t|
      t.references :professor
      t.references :research_area

      t.timestamps
    end
  end

  def self.down
    drop_table :professor_research_areas
  end
end

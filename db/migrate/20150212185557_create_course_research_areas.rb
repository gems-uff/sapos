# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateCourseResearchAreas < ActiveRecord::Migration[5.1]
  def self.up
    create_table :course_research_areas do |t|
      t.references :course
      t.references :research_area

      t.timestamps
    end

    Course.all.each do |t| 
      CourseResearchArea.create(course_id: t.id,research_area_id: t.research_area_id)
    end

    remove_column :courses, :research_area_id

  end

  def self.down
    add_column :courses, :research_area_id, :integer

    
    CourseResearchArea.all.each do |t| 
      c = Course.find(t.course_id)
      c.research_area_id = t.research_area_id
      c.save
      
    end

    drop_table :course_research_areas
  end
end

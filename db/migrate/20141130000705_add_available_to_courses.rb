class AddAvailableToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :available, :boolean, :default => true
  end
end

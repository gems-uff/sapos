class AddWorkloadToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :workload, :integer
  end
end

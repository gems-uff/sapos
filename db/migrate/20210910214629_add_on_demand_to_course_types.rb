class AddOnDemandToCourseTypes < ActiveRecord::Migration[6.0]
  def change
    add_column :course_types, :on_demand, :boolean, null: false , default: false
  end
end

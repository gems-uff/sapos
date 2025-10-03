class AddObsGenderAtStudent < ActiveRecord::Migration[7.0]
  def up
    add_column :students, :obs_gender, :text
  end
  def down
    remove_column :students, :obs_gender
  end
end

class AlterRefugeeToHumanityPolicies < ActiveRecord::Migration[7.0]
  def up
    rename_column :students,:refugee,:humanity_policy
    remove_column :students, :obs_refugee
  end
  def down
    rename_column :students,:humanity_policy,:refugee
    add_column :students, :obs_refugee, :text
  end
end

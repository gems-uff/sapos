class AlterStudentRefugeeToHumanityPolicy < ActiveRecord::Migration[7.0]
  def up
    rename_column :students, :refugee, :humanity_policy
  end
  def down
    rename_column :students,:humanity_policy, :refugee
  end
end

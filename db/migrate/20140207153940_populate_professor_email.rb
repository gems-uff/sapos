class PopulateProfessorEmail < ActiveRecord::Migration
  def up
    add_index :users, :email
    add_index :professors, :email
  end

  def down
    remove_index :users, :column => [:email]
    remove_index :professors, :column => [:email]
  end
end

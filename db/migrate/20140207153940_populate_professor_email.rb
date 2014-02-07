class PopulateProfessorEmail < ActiveRecord::Migration
  def up
    add_index :users, :email
    add_index :professors, :email
    User.all.each do |user| 
      professor = Professor.where(:name => user.name).first
      unless professor.nil?
        professor.email = user.email
        professor.save
      end
    end
  end

  def down
    remove_index :users, :column => [:email]
    remove_index :professors, :column => [:email]
  end
end

class AddUserReferenceToProfessor < ActiveRecord::Migration[5.1]
  def change
    add_reference :professors, :user, foreign_key: true
  end
end

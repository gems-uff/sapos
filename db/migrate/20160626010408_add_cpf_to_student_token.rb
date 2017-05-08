class AddCpfToStudentToken < ActiveRecord::Migration
  def change
    add_column :student_tokens, :cpf, :string
    add_column :student_tokens, :email, :string
  end
end

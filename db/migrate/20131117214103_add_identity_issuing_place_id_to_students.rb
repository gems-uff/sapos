class AddIdentityIssuingPlaceIdToStudents < ActiveRecord::Migration
  def change
    add_column :students, :identity_issuing_place, :string
  end
end

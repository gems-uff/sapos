class AddIdentityIssuingPlaceToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :identity_issuing_place, :string
  end
end

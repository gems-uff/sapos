class AddReferenceToForm < ActiveRecord::Migration[5.1]
  def change
	add_reference :forms, :queries, index: true
  end
end

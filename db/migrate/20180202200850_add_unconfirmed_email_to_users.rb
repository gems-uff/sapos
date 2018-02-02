class AddUnconfirmedEmailToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :unconfirmed_email, :string	  
  end
end

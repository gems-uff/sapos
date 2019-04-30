class CreateForms < ActiveRecord::Migration[5.1]
  def change
    create_table :forms do |t|
         t.column :nome, :string, :limit => 32, :null => false
         t.column :query_id, :integer
         t.column :descricao, :text
	       t.column :template, :text
         t.column :created_at, :timestamp
      end
  end
end

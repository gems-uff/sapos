class CreateTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :templates do |t|
      t.string :name
      t.string :description
      t.string :code
      t.timestamps
    end
  end
end

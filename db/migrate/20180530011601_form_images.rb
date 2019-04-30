class FormImages < ActiveRecord::Migration[5.1]
  def change
    create_table :form_images do |t|
      t.string :name
      t.text :text
      t.string :image
      t.integer :form_id
      t.timestamps
    end
  end
end

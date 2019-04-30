class CreateFormTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :form_templates do |t|
      t.string :name
      t.string :description
      t.string :code
      t.timestamps
    end
  end
end

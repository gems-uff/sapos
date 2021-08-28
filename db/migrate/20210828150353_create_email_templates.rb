class CreateEmailTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :email_templates do |t|
      t.string :name
      t.string :to
      t.string :subject
      t.text :body
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end

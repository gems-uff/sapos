class CreateAssertions < ActiveRecord::Migration[7.0]
  def change
    create_table :assertions do |t|
      t.string :name

      t.timestamps
    end
  end
end
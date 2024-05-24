class CreateAffiliation < ActiveRecord::Migration[7.0]
  def up
    create_table :affiliations do |t|
      t.belongs_to :professor, index: true
      t.belongs_to :institution, index: true
      t.boolean :active
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
    remove_column :professors, :institution_id
  end
  def down
    drop_table :affiliations
    add_column :professors, :institution_id, :integer
    add_index :professors, :institution_id
  end
end

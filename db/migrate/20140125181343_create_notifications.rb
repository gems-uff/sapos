class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :to_template
      t.string :subject_template
      t.string :body_template
      t.text :sql_query
      t.integer :notification_offset
      t.integer :query_offset
      t.string :frequency

      t.timestamps
    end
  end
end

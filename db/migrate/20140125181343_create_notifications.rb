class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :title
      t.string :to_template
      t.string :subject_template
      t.text :body_template
      t.text :sql_query
      t.integer :notification_offset
      t.integer :query_offset
      t.string :frequency
      t.datetime :next_execution
      t.timestamps
    end
  end
end

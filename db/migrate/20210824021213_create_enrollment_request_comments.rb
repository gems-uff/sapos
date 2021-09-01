class CreateEnrollmentRequestComments < ActiveRecord::Migration[6.0]
  def change
    create_table :enrollment_request_comments do |t|
      t.text :message
      t.references :enrollment_request
      t.references :user

      t.timestamps
    end
  end
end

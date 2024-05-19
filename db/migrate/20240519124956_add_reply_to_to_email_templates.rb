class AddReplyToToEmailTemplates < ActiveRecord::Migration[7.0]
  def up
    add_column :email_templates, :reply_to, :string, limit: 255
  end
  def down
    remove_column :email_templates, :reply_to
  end
end

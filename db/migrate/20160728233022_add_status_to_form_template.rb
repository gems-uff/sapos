class AddStatusToFormTemplate < ActiveRecord::Migration
  def change
    add_column :form_templates, :status, :string
  end
end

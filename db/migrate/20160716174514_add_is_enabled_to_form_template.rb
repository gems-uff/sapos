class AddIsEnabledToFormTemplate < ActiveRecord::Migration
  def change
    add_column :form_templates, :is_enabled, :boolean, :default => true
  end
end
